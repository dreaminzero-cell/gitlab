# frozen_string_literal: true

module EE
  module Gitlab
    module Template
      module GitlabCiYmlTemplate
        extend ActiveSupport::Concern

        class_methods do
          extend ::Gitlab::Utils::Override

          override :categories
          def categories
            super.merge(categories_ee)
          end

          override :disabled_templates
          def disabled_templates
            []
          end

          private

          def categories_ee
            {
              'Security' => 'Security'
            }
          end
        end
      end
    end
  end
end
