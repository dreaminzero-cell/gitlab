# frozen_string_literal: true

require 'spec_helper'

describe Projects::Security::Vulnerabilities::NotesController do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project) }
  let_it_be(:vulnerability) { create(:vulnerability, project: project) }

  let!(:note) { create(:note, noteable: vulnerability, project: project) }

  it_behaves_like SecurityDashboardsPermissions do
    let(:vulnerable) { project }

    let(:security_dashboard_action) do
      get :index, params: { namespace_id: project.namespace, project_id: project, vulnerability_id: vulnerability }
    end
  end

  before do
    stub_licensed_features(security_dashboard: true)
  end

  describe 'GET index' do
    subject(:view_all_notes) do
      get :index, params: { namespace_id: project.namespace, project_id: project, vulnerability_id: vulnerability }
    end

    before do
      project.add_developer(user)
      sign_in(user)
    end

    it 'responds with array of notes' do
      view_all_notes

      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to match_response_schema('vulnerability_notes', dir: 'ee')

      expect(json_response['notes']).to be_an Array
      expect(json_response['notes'].pluck('id')).to eq([note.id.to_s])
    end

    context 'when the feature flag is disabled' do
      before do
        stub_feature_flags(first_class_vulnerabilities: false)
      end

      it 'renders the 404 page' do
        view_all_notes

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe 'POST create' do
    let(:note_params) { { note: 'some note' } }
    let(:extra_params) { {} }
    let(:request_params) do
      {
        namespace_id: project.namespace,
        project_id: project,
        vulnerability_id: vulnerability,
        note: note_params,
        format: :json
      }
    end

    subject(:create_note) { post :create, params: request_params.merge(extra_params) }

    before do
      project.add_developer(user)
      sign_in(user)
    end

    context 'when note is empty' do
      let(:note_params) { { note: '' } }

      it 'does not create new note' do
        expect { create_note }.not_to change { Note.count }
      end

      it 'returns status 422' do
        create_note

        expect(response).to have_gitlab_http_status(:unprocessable_entity)
      end
    end

    context 'when note is provided' do
      let(:note_params) { { note: 'some note' } }

      it 'creates new note' do
        expect { create_note }.to change { Note.count }.by(1)
      end

      it 'returns status 200' do
        create_note

        expect(response).to have_gitlab_http_status(:ok)
      end

      context 'when replying to the discussion' do
        let(:extra_params) { { in_reply_to_discussion_id: note.discussion_id } }

        it 'creates new note in reply to discussion' do
          expect { create_note }.to change { Note.where(discussion_id: note.discussion_id).count }.by(1)
        end

        it 'returns status 200' do
          create_note

          expect(response).to have_gitlab_http_status(:ok)
        end

        context 'when return_discussion param is set' do
          let(:extra_params) { { in_reply_to_discussion_id: note.discussion_id, return_discussion: 'true' } }

          it 'returns discussion JSON when the return_discussion param is set' do
            create_note

            expect(response).to have_gitlab_http_status(:ok)
            expect(json_response).to have_key 'discussion'
            expect(json_response.dig('discussion', 'notes', -1, 'note')).to eq(note_params[:note])
          end
        end
      end
    end
  end

  describe 'PUT update' do
    let(:note_params) { { note: 'some note' } }
    let(:request_params) do
      {
        id: note,
        namespace_id: project.namespace,
        project_id: project,
        vulnerability_id: vulnerability,
        note: note_params,
        format: :json
      }
    end

    subject(:update_note) { put :update, params: request_params }

    before do
      project.add_developer(user)
      sign_in(user)
    end

    context 'when user is not an author of a note' do
      it 'returns status 404' do
        update_note

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when user is not an author of a note' do
      let!(:note) { create(:note, noteable: vulnerability, project: project, author: user) }

      context 'when note is provided' do
        let(:note_params) { { note: 'some note' } }

        it 'updates note' do
          expect { update_note }.to change { note.reload.note }.to(note_params[:note])
        end

        it 'returns status 200' do
          update_note

          expect(response).to have_gitlab_http_status(:ok)
        end
      end
    end
  end

  describe 'DELETE destroy' do
    let(:request_params) do
      {
        id: note,
        namespace_id: project.namespace,
        project_id: project,
        vulnerability_id: vulnerability
      }
    end

    subject(:delete_note) { delete :destroy, params: request_params }

    before do
      project.add_developer(user)
      sign_in(user)
    end

    context 'when user is not an author of a note' do
      it 'does not delete the note' do
        expect { delete_note }.not_to change { Note.count }
      end

      it 'returns status 404' do
        delete_note

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when user is not an author of a note' do
      let!(:note) { create(:note, noteable: vulnerability, project: project, author: user) }

      it 'does not delete the note' do
        expect { delete_note }.to change { Note.count }.by(-1)
      end

      it 'returns status 404' do
        delete_note

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe 'POST toggle_award_emoji' do
    let(:request_params) do
      {
        id: note,
        namespace_id: project.namespace,
        project_id: project,
        vulnerability_id: vulnerability,
        format: :json
      }
    end

    subject(:toggle_award_emoji) { post :toggle_award_emoji, params: request_params.merge(name: emoji_name) }

    before do
      sign_in(user)
      project.add_developer(user)
    end


    let(:emoji_name) { 'thumbsup' }

    it 'creates the award emoji' do
      expect { toggle_award_emoji }.to change { note.award_emoji.count }.by(1)

      expect(response).to have_gitlab_http_status(:ok)
    end

    context 'when award emoji was already created' do
      before do
        post :toggle_award_emoji, params: request_params.merge(name: emoji_name)
      end

      it 'deletes the award emoji' do
        expect { toggle_award_emoji }.to change { AwardEmoji.count }.by(-1)

        expect(response).to have_gitlab_http_status(:ok)
      end
    end
  end
end
