# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Auth::AuthFinders do
  include described_class

  let(:user) { create(:user) }
  let(:env) do
    {
      'rack.input' => ''
    }
  end
  let(:request) { ActionDispatch::Request.new(env)}
  let(:params) { request.params }

  def set_param(key, value)
    request.update_param(key, value)
  end

  shared_examples 'find user from job token' do
    context 'when route is allowed to be authenticated' do
      let(:route_authentication_setting) { { job_token_allowed: true } }

      it "returns an Unauthorized exception for an invalid token" do
        set_token('invalid token')

        expect { subject }.to raise_error(Gitlab::Auth::UnauthorizedError)
      end

      it "return user if token is valid" do
        set_token(job.token)

        expect(subject).to eq(user)
        expect(@current_authenticated_job).to eq job
      end
    end
  end

  describe '#validate_access_token!' do
    subject { validate_access_token! }

    context 'with a job token' do
      let(:route_authentication_setting) { { job_token_allowed: true } }
      let(:job) { create(:ci_build, user: user) }

      before do
        env['HTTP_AUTHORIZATION'] = "Bearer #{job.token}"
        find_user_from_bearer_token
      end

      it 'does not raise an error' do
        expect { subject }.not_to raise_error
      end
    end

    context 'without a job token' do
      let(:personal_access_token) { create(:personal_access_token, user: user) }

      before do
        personal_access_token.revoke!
        allow_any_instance_of(described_class).to receive(:access_token).and_return(personal_access_token)
      end

      it 'delegates the logic to super' do
        expect { subject }.to raise_error(Gitlab::Auth::RevokedError)
      end
    end
  end
end
