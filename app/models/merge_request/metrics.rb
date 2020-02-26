# frozen_string_literal: true

class MergeRequest::Metrics < ApplicationRecord
  include Gitlab::Utils::StrongMemoize

  belongs_to :merge_request
  belongs_to :pipeline, class_name: 'Ci::Pipeline', foreign_key: :pipeline_id
  belongs_to :latest_closed_by, class_name: 'User'
  belongs_to :merged_by, class_name: 'User'
end

MergeRequest::Metrics.prepend_if_ee('EE::MergeRequest::Metrics')
