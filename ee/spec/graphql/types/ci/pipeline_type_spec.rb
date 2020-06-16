# frozen_string_literal: true

require 'spec_helper'

describe GitlabSchema.types['Pipeline'] do
  it { expect(described_class.graphql_name).to eq('Pipeline') }

  it 'includes the ee specific fields' do
    expected_fields = %w[
        security_report_summary
    ]

    expect(described_class).to include_graphql_fields(*expected_fields)
  end
end