# frozen_string_literal: true

module EE
  module Types
    module GroupType
      extend ActiveSupport::Concern

      prepended do
        %i[epics group_timelogs].each do |feature|
          field "#{feature}_enabled", GraphQL::BOOLEAN_TYPE, null: true, resolve: -> (group, args, ctx) do
            group.feature_available?(feature)
          end, description: "Indicates if #{feature.to_s.humanize} are enabled for namespace"
        end

        field :epic, ::Types::EpicType, null: true,
              description: 'Find a single epic',
              resolver: ::Resolvers::EpicsResolver.single

        field :epics, ::Types::EpicType.connection_type, null: true,
              description: 'Find epics',
              max_page_size: 2000,
              resolver: ::Resolvers::EpicsResolver

        field :timelogs, ::Types::TimelogType.connection_type, null: false,
              description: 'Time logged in issues by group members',
              complexity: 5,
              resolver: ::Resolvers::TimelogResolver

        field :vulnerabilities,
              ::Types::VulnerabilityType.connection_type,
              null: true,
              description: 'Vulnerabilities reported on the projects in the group and its subgroups',
              resolver: Resolvers::VulnerabilitiesResolver,
              feature_flag: :first_class_vulnerabilities
      end
    end
  end
end
