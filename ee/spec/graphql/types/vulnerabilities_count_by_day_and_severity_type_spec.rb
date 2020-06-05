# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['VulnerabilitiesCountByDayAndSeverity'] do
  it { expect(described_class).to have_graphql_fields(:count, :day, :severity) }
end