# frozen_string_literal: true

require 'spec_helper'

describe StatusPage::PublishDetailsService do
  let_it_be(:project, refind: true) { create(:project) }
  let(:storage_client) { instance_double(StatusPage::Storage::S3Client) }
  let(:serializer) { instance_double(StatusPage::IncidentSerializer) }
  let(:issue) { instance_double(Issue) }
  let(:user_notes) { double(:user_notes) }
  let(:incident_id) { 1 }
  let(:key) { StatusPage::Storage.details_path(incident_id) }
  let(:content) { { id: incident_id } }
  let(:content_json) { content.to_json }

  let(:service) do
    described_class.new(
      project: project, storage_client: storage_client, serializer: serializer
    )
  end

  subject(:result) { service.execute(issue, user_notes) }

  describe '#execute' do
    context 'when license is available' do
      before do
        allow(serializer).to receive(:represent_details).with(issue, user_notes)
          .and_return(content)
      end

      include_examples 'publish incidents'

      context 'when serialized content is missing id' do
        let(:content) { { other_id: incident_id } }

        it 'returns an error' do
          expect(result).to be_error
          expect(result.message).to eq('Missing object key')
        end
      end
    end
  end
end
