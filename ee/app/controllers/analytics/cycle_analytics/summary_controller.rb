# frozen_string_literal: true

module Analytics
  module CycleAnalytics
    class SummaryController < BaseSummaryController
      def summary(group_level)
        group_level.summary
      end
    end
  end
end
