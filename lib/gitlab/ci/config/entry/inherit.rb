# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module Entry
        ##
        # This class represents a inherit entry
        #
        class Inherit < ::Gitlab::Config::Entry::Node
          include ::Gitlab::Config::Entry::Configurable

          ALLOWED_KEYS = %i[default variables].freeze

          validations do
            validates :config, allowed_keys: ALLOWED_KEYS
          end

          entry :default, ::Gitlab::Config::Entry::Boolean,
            description: 'Indicates whether to inherit `default:`.',
            default: true

          entry :variables, ::Gitlab::Config::Entry::Boolean,
            description: 'Indicates whether to inherit `variables:`.',
            default: true
        end
      end
    end
  end
end
