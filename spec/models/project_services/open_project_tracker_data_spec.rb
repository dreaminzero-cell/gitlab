# frozen_string_literal: true

require 'spec_helper'

describe OpenProjectTrackerData do
  describe 'Associations' do
    it { is_expected.to belong_to(:service) }
  end

  describe 'closed_status_id' do
    it 'returns the set value' do
      expect(build(:open_project_tracker_data).closed_status_id).to eq('15')
    end

    it 'returns the default value if not set' do
      expect(build(:open_project_tracker_data, closed_status_id: nil).closed_status_id).to eq('13')
    end
  end
end
