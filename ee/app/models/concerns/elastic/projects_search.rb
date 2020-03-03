# frozen_string_literal: true

module Elastic
  module ProjectsSearch
    extend ActiveSupport::Concern

    include ApplicationVersionedSearch

    INDEXED_ASSOCIATIONS = [
      :issues,
      :merge_requests,
      :snippets,
      :notes,
      :milestones
    ].freeze

    included do
      def use_elasticsearch?
        ::Gitlab::CurrentSettings.elasticsearch_indexes_project?(self)
      end

      def maintain_elasticsearch_incremental_bulk
        # TODO: ElasticIndexerWorker does extra work for project hooks, so we
        # can't use the incremental-bulk indexer for projects yet.
        #
        # https://gitlab.com/gitlab-org/gitlab/issues/207494
        false
      end

      def each_indexed_association
        INDEXED_ASSOCIATIONS.each do |association_name|
          association = self.association(association_name)
          scope = association.scope
          klass = association.klass

          if klass == Note
            scope = scope.searchable
          end

          yield klass, scope
        end
      end
    end
  end
end
