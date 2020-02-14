# frozen_string_literal: true

require 'spec_helper'

describe Users::BlockService do
  let(:current_user) { create(:admin) }

  subject(:service) { described_class.new(current_user) }

  describe '#execute' do
    let(:user) { create(:user) }

    subject(:operation) { service.execute(user) }

    describe 'audit events' do
      context 'when licensed' do
        before do
          stub_licensed_features(admin_audit_log: true)
        end

        context 'when user block operation succeeds' do
          it 'logs an audit event' do
            expect { operation }.to change { AuditEvent.count }.by(1)
          end

          it 'logs the audit event info' do
            operation

            expect(AuditEvent.last).to have_attributes(
              details: hash_including(custom_message: 'Blocked user')
            )
          end
        end

        context 'when user block operation fails' do
          before do
            allow(user).to receive(:block).and_return(false)
          end

          it 'does not log any audit event' do
            expect { operation }.not_to change { AuditEvent.count }
          end
        end
      end

      context 'when not licensed' do
        before do
          stub_licensed_features(
            admin_audit_log: false,
            audit_events: false,
            extended_audit_events: false
          )
        end

        it 'does not log audit event' do
          expect { operation }.not_to change(AuditEvent, :count)
        end
      end
    end
  end
end
