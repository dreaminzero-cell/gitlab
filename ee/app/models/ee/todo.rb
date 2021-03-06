# frozen_string_literal: true

module EE
  module Todo
    extend ActiveSupport::Concern
    extend ::Gitlab::Utils::Override

    prepended do
      include UsageStatistics
    end

    override :resource_parent
    def resource_parent
      project || group
    end

    def for_design?
      target_type == DesignManagement::Design.name
    end
  end
end
