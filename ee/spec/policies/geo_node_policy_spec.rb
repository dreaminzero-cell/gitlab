# frozen_string_literal: true

require 'spec_helper'

describe GeoNodePolicy do
  let_it_be(:geo_node) { create(:geo_node) }

  subject(:policy) { described_class.new(current_user, geo_node) }

  context 'when the user is an admin' do
    let(:current_user) { create(:user, :admin) }

    it 'allows read_geo_node for any GeoNode' do
      expect(policy).to be_allowed(:read_geo_node)
    end
  end

  context 'when the user is not an admin' do
    let(:current_user) { create(:user) }

    it 'disallows read_geo_node for any GeoNode' do
      expect(policy).to be_disallowed(:read_geo_node)
    end
  end
end
