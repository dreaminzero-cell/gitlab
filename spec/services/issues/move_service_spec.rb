# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Issues::MoveService do
  let_it_be(:user) { create(:user) }
  let_it_be(:author) { create(:user) }
  let_it_be(:title) { 'Some issue' }
  let_it_be(:original_content) { "Some issue description with mention to #{user.to_reference}" }
  let_it_be(:group) { create(:group, :private) }
  let_it_be(:sub_group_1) { create(:group, :private, parent: group) }
  let_it_be(:sub_group_2) { create(:group, :private, parent: group) }
  let_it_be(:old_project) { create(:project, namespace: sub_group_1) }
  let_it_be(:new_project) { create(:project, namespace: sub_group_2) }

  let(:old_issue) do
    create(:issue, title: title, description: original_content, project: old_project, author: author)
  end

  subject(:move_service) do
    described_class.new(old_project, user)
  end

  shared_context 'user can move issue' do
    before do
      old_project.add_reporter(user)
      new_project.add_reporter(user)
    end
  end

  describe '#execute' do
    shared_context 'issue move executed' do
      let!(:new_issue) { move_service.execute(old_issue, new_project) }
    end

    context 'issue movable' do
      include_context 'user can move issue'

      include_examples 'rewrites content' do
        let(:source_project) { old_project }
        let(:target_project) { new_project }
        let(:execute_service) { move_service.execute(old_issue, target_project) }
        let(:new_content) { execute_service.description }
      end

      context 'generic issue' do
        include_context 'issue move executed'

        it 'creates a new issue in a new project' do
          expect(new_issue.project).to eq new_project
        end

        it 'copies issue title' do
          expect(new_issue.title).to eq title
        end

        it 'copies issue description' do
          expect(new_issue.description).to eq original_content
        end

        it 'adds system note to old issue at the end' do
          expect(old_issue.notes.last.note).to start_with 'moved to'
        end

        it 'adds system note to new issue at the end' do
          expect(new_issue.notes.last.note).to start_with 'moved from'
        end

        it 'closes old issue' do
          expect(old_issue.closed?).to be true
        end

        it 'persists new issue' do
          expect(new_issue.persisted?).to be true
        end

        it 'persists all changes' do
          expect(old_issue.changed?).to be false
          expect(new_issue.changed?).to be false
        end

        it 'preserves author' do
          expect(new_issue.author).to eq author
        end

        it 'creates a new internal id for issue' do
          expect(new_issue.iid).to be 1
        end

        it 'marks issue as moved' do
          expect(old_issue.moved?).to eq true
          expect(old_issue.moved_to).to eq new_issue
        end

        it 'preserves create time' do
          expect(old_issue.created_at).to eq new_issue.created_at
        end
      end

      context 'issue with award emoji' do
        let!(:award_emoji) { create(:award_emoji, awardable: old_issue) }

        it 'copies the award emoji' do
          old_issue.reload
          new_issue = move_service.execute(old_issue, new_project)

          expect(old_issue.award_emoji.first.name).to eq new_issue.reload.award_emoji.first.name
        end
      end

      context 'issue with assignee' do
        let_it_be(:assignee) { create(:user) }

        before do
          old_issue.assignees = [assignee]
        end

        it 'preserves assignee with access to the new issue' do
          new_project.add_reporter(assignee)

          new_issue = move_service.execute(old_issue, new_project)

          expect(new_issue.assignees).to eq([assignee])
        end

        it 'ignores assignee without access to the new issue' do
          new_issue = move_service.execute(old_issue, new_project)

          expect(new_issue.assignees).to be_empty
        end
      end

      context 'moving to same project' do
        let(:new_project) { old_project }

        it 'raises error' do
          expect { move_service.execute(old_issue, new_project) }
            .to raise_error(StandardError, /Cannot move issue/)
        end
      end

      context 'project issue hooks' do
        let!(:hook) { create(:project_hook, project: old_project, issues_events: true) }

        it 'executes project issue hooks' do
          allow_next_instance_of(WebHookService) do |instance|
            allow(instance).to receive(:execute)
          end

          # Ideally, we'd test that `WebHookWorker.jobs.size` increased by 1,
          # but since the entire spec run takes place in a transaction, we never
          # actually get to the `after_commit` hook that queues these jobs.
          expect { move_service.execute(old_issue, new_project) }
            .not_to raise_error # Sidekiq::Worker::EnqueueFromTransactionError
        end
      end

      context 'issue with notes' do
        context 'does this need a context?' do
          include_examples 'rewrites content' do
            let!(:note) { create(:note, note: original_content, noteable: old_issue, project: old_project) }
            let(:original_content) { 'My note' }
            let(:execute_service) { move_service.execute(old_issue, new_project) }
            let(:source_project) { old_project }
            let(:target_project) { new_project }
            let(:new_content) { execute_service.notes.first.note }
          end
        end

        # TODO rename this to be about properties or something?
        context 'simple notes' do
          let!(:notes) do
            [
              create(:note, noteable: old_issue, project: old_project, created_at: 2.weeks.ago, updated_at: 1.week.ago),
              create(:note, noteable: old_issue, project: old_project),
              create(:note, system: true, noteable: old_issue, project: old_project)
            ]
          end

          let!(:system_note_metadata) { create(:system_note_metadata, note: notes.last) }
          let!(:award_emoji) { create(:award_emoji, awardable: notes.first, name: 'thumbsup')}
          let(:copied_notes) { new_issue.notes.limit(notes.size) } # Remove the system note added by the copy itself

          include_context 'issue move executed'

          it 'copies existing notes in valid order' do
            expect(copied_notes.order('id ASC').pluck(:note)).to eq(notes.map(&:note))
          end

          it 'copies all the issue notes' do
            expect(copied_notes.count).to eq(3)
          end

          it 'does not change the note attributes' do
            new_note = copied_notes.first

            expect(new_note.note).to eq(note1.note)
            expect(new_note.author).to eq(note1.author)
          end

          it 'copies the award emojis' do
            new_note = copied_notes.first
            new_note.award_emoji.first.name = 'thumbsup'
          end

          it 'copies system_note_metadata for system note' do
            new_note = copied_notes.last

            expect(new_note.system_note_metadata.action).to eq(system_note_metadata.action)
            expect(new_note.system_note_metadata.id).not_to eq(system_note_metadata.id)
          end
        end

        context 'notes with mentions' do
          let!(:note_with_mention) { create(:note, noteable: old_issue, author: author, project: old_project, note: "note with mention #{user.to_reference}") }
          let!(:note_with_no_mention) { create(:note, noteable: old_issue, author: author, project: old_project, note: "note without mention") }

          include_context 'issue move executed'

          it 'saves user mentions with actual mentions for new issue' do
            expect(new_issue.user_mentions.find_by(note_id: nil).mentioned_users_ids).to match_array([user.id])
            expect(new_issue.user_mentions.where.not(note_id: nil).first.mentioned_users_ids).to match_array([user.id])
            expect(new_issue.user_mentions.where.not(note_id: nil).count).to eq 1
            expect(new_issue.user_mentions.count).to eq 2
          end
        end

        # context 'notes with reference' do
        #   let(:other_issue) { create(:issue, project: old_project) }
        #   let(:merge_request) { create(:merge_request) }
        #   let(:text) do
        #     "See ##{other_issue.iid} and #{merge_request.project.full_path}!#{merge_request.iid}"
        #   end
        #   let!(:note) { create(:note, noteable: old_issue, note: text, project: old_project) }

        #   include_context 'issue move executed'

        #   it 'rewrites the references correctly' do
        #     new_note = new_issue.notes.first

        #     expected_text = "See #{other_issue.project.path}##{other_issue.iid} and #{merge_request.project.full_path}!#{merge_request.iid}"

        #     expect(new_note.note).to eq(expected_text)
        #     expect(new_note.author).to eq(note.author)
        #   end
        # end

        # context 'notes with upload' do
        #   let(:uploader) { build(:file_uploader, project: old_project) }
        #   let(:text) { "Simple text with image: #{uploader.markdown_link} "}
        #   let!(:note) { create(:note, noteable: old_issue, note: text, project: old_project) }

        #   include_context 'issue move executed'

        #   it 'rewrites note content correctly' do
        #     new_note = new_issue.notes.first

        #     expect(note.note).to match(/Simple text with image: #{FileUploader::MARKDOWN_PATTERN}/)
        #     expect(new_note.note).to match(/Simple text with image: #{FileUploader::MARKDOWN_PATTERN}/)
        #     expect(note.note).not_to eq(new_note.note)
        #     expect(note.note_html).not_to eq(new_note.note_html)
        #   end
        # end

        context "discussion notes" do
          let(:note) { create(:note, noteable: old_issue, note: "sample note", project: old_project) }
          let!(:discussion) { create(:discussion_note_on_issue, in_reply_to: note, note: "reply to sample note") }

          include_context 'issue move executed'

          it 'rewrites discussion correctly' do
            expect(new_issue.notes.count).to eq(old_issue.notes.count)
            expect(new_issue.notes.where(discussion_id: discussion.discussion_id).count).to eq(0)
            expect(old_issue.notes.where(discussion_id: discussion.discussion_id).count).to eq(1)
          end
        end
      end

      context 'issue with a design', :clean_gitlab_redis_cache do
        let!(:design) { create(:design, :with_lfs_file, issue: old_issue) }
        let!(:note) { create(:diff_note_on_design, noteable: design, issue: old_issue, project: old_issue.project) }

        include_context 'issue move executed'

        it 'copies the design and its notes', :sidekiq_inline do
          expect(new_issue.designs.size).to eq(1)
        end

        it 'copies the design notes', :sidekiq_inline do
          expect(new_issue.designs.first.notes.size).to eq(1)
        end
      end
    end

    describe 'move permissions' do
      let(:move) { move_service.execute(old_issue, new_project) }

      context 'user is reporter in both projects' do
        include_context 'user can move issue'
        it { expect { move }.not_to raise_error }
      end

      context 'user is reporter only in new project' do
        before do
          new_project.add_reporter(user)
        end

        it { expect { move }.to raise_error(StandardError, /permissions/) }
      end

      context 'user is reporter only in old project' do
        before do
          old_project.add_reporter(user)
        end

        it { expect { move }.to raise_error(StandardError, /permissions/) }
      end

      context 'user is reporter in one project and guest in another' do
        before do
          new_project.add_guest(user)
          old_project.add_reporter(user)
        end

        it { expect { move }.to raise_error(StandardError, /permissions/) }
      end

      context 'issue has already been moved' do
        include_context 'user can move issue'

        let(:moved_to_issue) { create(:issue) }

        let(:old_issue) do
          create(:issue, project: old_project, author: author,
                         moved_to: moved_to_issue)
        end

        it { expect { move }.to raise_error(StandardError, /permissions/) }
      end

      context 'issue is not persisted' do
        include_context 'user can move issue'
        let(:old_issue) { build(:issue, project: old_project, author: author) }

        it { expect { move }.to raise_error(StandardError, /permissions/) }
      end
    end
  end

  context 'updating sent notifications' do
    let!(:old_issue_notification_1) { create(:sent_notification, project: old_issue.project, noteable: old_issue) }
    let!(:old_issue_notification_2) { create(:sent_notification, project: old_issue.project, noteable: old_issue) }
    let!(:other_issue_notification) { create(:sent_notification, project: old_issue.project) }

    include_context 'user can move issue'

    context 'when issue is from service desk' do
      before do
        allow(old_issue).to receive(:from_service_desk?).and_return(true)
      end

      it 'updates moved issue sent notifications' do
        new_issue = move_service.execute(old_issue, new_project)

        old_issue_notification_1.reload
        old_issue_notification_2.reload
        expect(old_issue_notification_1.project_id).to eq(new_issue.project_id)
        expect(old_issue_notification_1.noteable_id).to eq(new_issue.id)
        expect(old_issue_notification_2.project_id).to eq(new_issue.project_id)
        expect(old_issue_notification_2.noteable_id).to eq(new_issue.id)
      end

      it 'does not update other issues sent notifications' do
        expect do
          move_service.execute(old_issue, new_project)
          other_issue_notification.reload
        end.not_to change { other_issue_notification.noteable_id }
      end
    end

    context 'when issue is not from service desk' do
      it 'does not update sent notifications' do
        move_service.execute(old_issue, new_project)

        old_issue_notification_1.reload
        old_issue_notification_2.reload
        expect(old_issue_notification_1.project_id).to eq(old_issue.project_id)
        expect(old_issue_notification_1.noteable_id).to eq(old_issue.id)
        expect(old_issue_notification_2.project_id).to eq(old_issue.project_id)
        expect(old_issue_notification_2.noteable_id).to eq(old_issue.id)
      end
    end
  end
end
