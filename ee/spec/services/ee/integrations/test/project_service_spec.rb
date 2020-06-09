# frozen_string_literal: true

require 'spec_helper'

describe ::Integrations::Test::ProjectService do
  let(:user) { double('user') }

  describe '#execute' do
    let(:project) { create(:project) }
    let(:event) { nil }
    let(:sample_data) { { data: 'sample' } }
    let(:success_result) { { success: true, result: {} } }

    subject { described_class.new(integration, user, event).execute }

    context 'without event specified' do
      context 'GitHubService' do
        let(:integration) { create(:github_service, project: project) }

        it_behaves_like 'tests for integration with pipeline data'
      end
    end
  end
end