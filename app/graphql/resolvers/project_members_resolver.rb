# frozen_string_literal: true

module Resolvers
  class ProjectMembersResolver < BaseResolver
    argument :search, GraphQL::STRING_TYPE,
              required: false,
              description: 'Search query'

    type Types::MemberType, null: true

    alias_method :project, :object

    def resolve(**args)
      return unless project.present?

      MembersFinder
        .new(project, context[:current_user], params: args)
        .execute
    end
  end
end
