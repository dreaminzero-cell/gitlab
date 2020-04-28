# frozen_string_literal: true

require 'spec_helper'

describe AlertManagement::Alert do
  describe 'associations' do
    it { is_expected.to belong_to(:project) }
    it { is_expected.to belong_to(:issue) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:title) }
    it { is_expected.to validate_presence_of(:events) }
    it { is_expected.to validate_presence_of(:severity) }
    it { is_expected.to validate_presence_of(:status) }
    it { is_expected.to validate_presence_of(:started_at) }

    it { is_expected.to validate_length_of(:title).is_at_most(200) }
    it { is_expected.to validate_length_of(:description).is_at_most(1000) }
    it { is_expected.to validate_length_of(:service).is_at_most(100) }
    it { is_expected.to validate_length_of(:monitoring_tool).is_at_most(100) }

    describe 'fingerprint' do
      let_it_be(:fingerprint) { 'fingerprint' }
      let_it_be(:existing_alert) { create(:alert_management_alert, fingerprint: fingerprint) }
      let(:new_alert) { build(:alert_management_alert, fingerprint: fingerprint, project: project) }

      subject { new_alert }

      context 'adding an alert with the same fingerprint' do
        context 'same project' do
          let(:project) { existing_alert.project }

          it { is_expected.not_to be_valid }
        end

        context 'different project' do
          let(:project) { create(:project) }

          it { is_expected.to be_valid }
        end
      end
    end

    describe 'hosts' do
      subject(:alert) { build(:alert_management_alert, hosts: hosts) }

      context 'over 255 total chars' do
        let(:hosts) { ['111.111.111.111'] * 18 }

        it { is_expected.not_to be_valid }
      end

      context 'under 255 chars' do
        let(:hosts) { ['111.111.111.111'] * 17 }

        it { is_expected.to be_valid }
      end
    end
  end

  describe 'enums' do
    let(:severity_values) do
      { critical: 0, high: 1, medium: 2, low: 3, info: 4, unknown: 5 }
    end

    let(:status_values) do
      { triggered: 0, acknowledged: 1, resolved: 2, ignored: 3 }
    end

    it { is_expected.to define_enum_for(:severity).with_values(severity_values) }
    it { is_expected.to define_enum_for(:status).with_values(status_values) }
  end

  describe '#trigger' do
    subject { alert.trigger }

    context 'when alert is in triggered state' do
      let(:alert) { create(:alert_management_alert) }

      it 'does not change the alert status' do
        expect { subject }.not_to change { alert.status }
      end
    end

    context 'when alert not in triggered state' do
      let(:alert) { create(:alert_management_alert, :resolved) }

      it 'changes the alert status to triggered' do
        expect { subject }.to change { alert.status }.to('triggered')
      end
    end
  end

  describe '#resolve' do
    let!(:ended_at) { Time.current }

    subject { alert.resolve(ended_at: ended_at) }

    context 'when alert already resolved' do
      let(:alert) { create(:alert_management_alert, :resolved) }

      it 'does not change the alert status' do
        expect { subject }.not_to change { alert.status }
      end

      it 'does not change the alert ended_at' do
        expect { subject }.not_to change { alert.ended_at }
      end
    end

    context 'when alert is not resolved' do
      let(:alert) { create(:alert_management_alert) }

      it 'changes alert status to "resolved"' do
        expect { subject }.to change { alert.status }.to('resolved')
      end

      it 'changes ended_at' do
        expect { subject }.to change { alert.ended_at }.to(ended_at)
      end
    end
  end
end
