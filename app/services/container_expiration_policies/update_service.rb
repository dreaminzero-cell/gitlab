# frozen_string_literal: true

module ContainerExpirationPolicies
  class UpdateService < BaseContainerService
    include Gitlab::Utils::StrongMemoize

    ALLOWED_ATTRIBUTES = %i[enabled cadence older_than keep_n name_regex name_regex_keep].freeze

    def execute
      return error('Access Denied', 403) unless allowed?

      if container_expiration_policy.update(container_expiration_policy_params)
        success(container_expiration_policy: container_expiration_policy)
      else
        error(container_expiration_policy.errors.full_messages.to_sentence || 'Bad request', 400)
      end
    end

    private

    def container_expiration_policy
      strong_memoize(:container_expiration_policy) do
        @container.container_expiration_policy || @container.build_container_expiration_policy
      end
    end

    def allowed?
      Ability.allowed?(current_user, :destroy_container_image, @container)
    end

    def container_expiration_policy_params
      @params.slice(*ALLOWED_ATTRIBUTES)
    end
  end
end
