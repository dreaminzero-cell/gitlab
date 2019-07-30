# frozen_string_literal: true

module Gitlab
  module CycleAnalytics
    class DataFilter
      include Gitlab::CycleAnalytics::MetricsTables
      include StageQueryHelpers

      def initialize(stage:, params: {})
        @stage = stage
      end

      def apply
        query = stage.model_to_query.arel_table
        query = filter_by_parent_model(query)
        query = stage.start_event.apply_query_customization(query)
        query = stage.end_event.apply_query_customization(query)
        query.where(duration.gt(zero_interval))
      end

      private

      attr_reader :stage

      def filter_by_parent_model(query)
        model_to_query = stage.model_to_query
        if stage.parent.is_a?(Project)
          if model_to_query.eql?(Issue)
            query.join(projects_table).on(issue_table[:project_id].eq(projects_table[:id]))
              .join(routes_table).on(projects_table[:namespace_id].eq(routes_table[:source_id]))
              .where(Issue.arel_table[:project_id].eq(stage.parent.id))
              .where(routes_table[:source_type].eq('Namespace'))
          elsif model_to_query.eql?(MergeRequest)
            query.join(projects_table).on(mr_table[:target_project_id].eq(projects_table[:id]))
              .join(routes_table).on(projects_table[:namespace_id].eq(routes_table[:source_id]))
              .where(mr_table[:target_project_id].eq(stage.parent.id))
              .where(routes_table[:source_type].eq('Namespace'))
          else
            raise "Unsupported model: #{model_to_query.class}"
          end
        elsif stage.parent.is_a?(Group)
          if model_to_query.eql?(Issue)
            query.join(projects_table).on(issue_table[:project_id].eq(projects_table[:id]))
              .join(routes_table).on(projects_table[:namespace_id].eq(routes_table[:source_id]))
              .where(routes_table[:path].matches("#{stage.parent.path}%"))
              .where(routes_table[:source_type].eq('Namespace'))
          elsif model_to_query.eql?(MergeRequest)
            query.join(projects_table).on(mr_table[:target_project_id].eq(projects_table[:id]))
              .join(routes_table).on(projects_table[:namespace_id].eq(routes_table[:source_id]))
              .where(routes_table[:path].matches("#{stage.parent.path}%"))
              .where(routes_table[:source_type].eq('Namespace'))
          else
            raise "Unsupported model: #{model_to_query.class}"
          end
        end
      end
    end
  end
end
