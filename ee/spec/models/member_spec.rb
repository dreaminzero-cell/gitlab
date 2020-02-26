# frozen_string_literal: true

require 'spec_helper'

describe Member, type: :model do
  describe '#notification_service' do
    it 'returns a NullNotificationService instance for LDAP users' do
      member = described_class.new

      allow(member).to receive(:ldap).and_return(true)

      expect(member.__send__(:notification_service))
        .to be_instance_of(::EE::NullNotificationService)
    end
  end

  describe '#is_using_seat' do
    let(:user) { FactoryBot.build :user }
    let(:group) { FactoryBot.create :group }
    let(:member) { FactoryBot.build_stubbed :group_member, group: group }

    before do
      allow(user).to receive(:using_gitlab_com_seat?).with(group).and_return true
      allow(user).to receive(:using_license_seat?).with(no_args).and_return true
      member.user = user
    end

    context 'when hosted on GL.com' do
      before do
        allow(Gitlab).to receive(:com?).and_return true
      end

      it 'calls users check for using the gitlab_com seat method' do
        expect(member.is_using_seat).to be_truthy
        expect(user).to have_received(:using_gitlab_com_seat?).with(group).once
        expect(user).not_to have_received(:using_license_seat?)
      end
    end

    context 'when not hosted on GL.com' do
      before do
        allow(Gitlab).to receive(:com?).and_return false
      end

      it 'calls users check for using the License seat method' do
        expect(member.is_using_seat).to be_truthy
        expect(user).to have_received(:using_license_seat?).with(no_args)
        expect(user).not_to have_received(:using_gitlab_com_seat?)
      end
    end
  end
end
