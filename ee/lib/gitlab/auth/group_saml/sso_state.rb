# frozen_string_literal: true

module Gitlab
  module Auth
    module GroupSaml
      class SsoState
        SESSION_STORE_KEY = :active_group_sso_sign_ins

        attr_reader :saml_provider_id

        def initialize(saml_provider_id)
          @saml_provider_id = saml_provider_id
        end

        def active?
          !session_available? || active_session_data[saml_provider_id]
        end

        def update_active(value)
          active_session_data[saml_provider_id] = value
        end

        private

        def active_session_data
          Gitlab::NamespacedSessionStore.new(SESSION_STORE_KEY)
        end

        def session_available?
          active_session_data.initiated?
        end
      end
    end
  end
end
