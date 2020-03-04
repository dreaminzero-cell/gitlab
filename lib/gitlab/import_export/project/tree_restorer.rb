# frozen_string_literal: true

module Gitlab
  module ImportExport
    module Project
      class TreeRestorer
        LARGE_PROJECT_FILE_SIZE_BYTES = 500.megabyte

        attr_reader :user
        attr_reader :shared
        attr_reader :project

        def initialize(user:, shared:, project:)
          @user = user
          @shared = shared
          @project = project
        end

        def restore
          @relation_readers = []
          @relation_readers << ImportExport::JSON::DedupLegacyReader.new(File.join(shared.export_path, 'project.json'), project.group)
          @relation_readers << ImportExport::JSON::LegacyReader.new(File.join(shared.export_path, 'project.json'))

          @relation_reader = @relation_readers.find(&:valid?)
          raise "missing relation reader for #{shared.export_path}" unless @relation_reader

          @project_members = []

          @relation_reader.each_relation('project_members') do |project_member|
            @project_members << project_member
          end

          if relation_tree_restorer.restore
            import_failure_service.with_retry(action: 'set_latest_merge_request_diff_ids!') do
              @project.merge_requests.set_latest_merge_request_diff_ids!
            end

            true
          else
            false
          end
        rescue => e
          @shared.error(e)
          false
        end

        private

        def relation_tree_restorer
          @relation_tree_restorer ||= RelationTreeRestorer.new(
            user: @user,
            shared: @shared,
            importable: @project,
            relation_reader: @relation_reader,
            object_builder: object_builder,
            members_mapper: members_mapper,
            relation_factory: relation_factory,
            reader: reader
          )
        end

        def members_mapper
          @members_mapper ||= Gitlab::ImportExport::MembersMapper.new(exported_members: @project_members,
                                                                      user: @user,
                                                                      importable: @project)
        end

        def object_builder
          Project::ObjectBuilder
        end

        def relation_factory
          Project::RelationFactory
        end

        def reader
          @reader ||= Gitlab::ImportExport::Reader.new(shared: @shared)
        end

        def import_failure_service
          @import_failure_service ||= ImportFailureService.new(@project)
        end
      end
    end
  end
end
