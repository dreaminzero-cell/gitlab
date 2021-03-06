# frozen_string_literal: true

require 'spec_helper'

describe WikiPages::CreateService do
  let(:project) { create(:project, :wiki_repo) }
  let(:user) { create(:user) }
  let(:page_title) { 'Title' }

  let(:opts) do
    {
      title: page_title,
      content: 'Content for wiki page',
      format: 'markdown'
    }
  end

  subject(:service) { described_class.new(project, user, opts) }

  before do
    project.add_developer(user)
  end

  describe '#execute' do
    it 'creates wiki page with valid attributes' do
      page = service.execute

      expect(page).to be_valid
      expect(page.title).to eq(opts[:title])
      expect(page.content).to eq(opts[:content])
      expect(page.format).to eq(opts[:format].to_sym)
    end

    it 'executes webhooks' do
      expect(service).to receive(:execute_hooks).once.with(WikiPage)

      service.execute
    end

    it 'counts wiki page creation' do
      counter = Gitlab::UsageDataCounters::WikiPageCounter

      expect { service.execute }.to change { counter.read(:create) }.by 1
    end

    shared_examples 'correct event created' do
      it 'creates appropriate events' do
        expect { service.execute }.to change { Event.count }.by 1

        expect(Event.recent.first).to have_attributes(
          action: Event::CREATED,
          target: have_attributes(canonical_slug: page_title)
        )
      end
    end

    context 'the new page is at the top level' do
      let(:page_title) { 'root-level-page' }

      include_examples 'correct event created'
    end

    context 'the new page is in a subsection' do
      let(:page_title) { 'subsection/page' }

      include_examples 'correct event created'
    end

    context 'the feature is disabled' do
      before do
        stub_feature_flags(wiki_events: false)
      end

      it 'does not record the activity' do
        expect { service.execute }.not_to change(Event, :count)
      end
    end

    context 'when the options are bad' do
      let(:page_title) { '' }

      it 'does not count a creation event' do
        counter = Gitlab::UsageDataCounters::WikiPageCounter

        expect { service.execute }.not_to change { counter.read(:create) }
      end

      it 'does not record the activity' do
        expect { service.execute }.not_to change(Event, :count)
      end

      it 'reports the error' do
        expect(service.execute).to be_invalid
          .and have_attributes(errors: be_present)
      end
    end
  end
end
