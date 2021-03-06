# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::UrlBuilder do
  subject { described_class }

  describe '.build' do
    using RSpec::Parameterized::TableSyntax

    where(:factory, :path_generator) do
      :design                | ->(design)        { "/#{design.project.full_path}/-/design_management/designs/#{design.id}/raw_image" }
      :epic                  | ->(epic)          { "/groups/#{epic.group.full_path}/-/epics/#{epic.iid}" }
      :vulnerability         | ->(vulnerability) { "/#{vulnerability.project.full_path}/-/security/vulnerabilities/#{vulnerability.id}" }

      :note_on_epic          | ->(note)          { "/groups/#{note.noteable.group.full_path}/-/epics/#{note.noteable.iid}#note_#{note.id}" }
      :note_on_vulnerability | ->(note)          { "/#{note.project.full_path}/-/security/vulnerabilities/#{note.noteable.id}#note_#{note.id}" }
    end

    with_them do
      let(:object) { build_stubbed(factory) }
      let(:path) { path_generator.call(object) }

      it 'returns the full URL' do
        expect(subject.build(object)).to eq("#{Settings.gitlab['url']}#{path}")
      end

      it 'returns only the path if only_path is set' do
        expect(subject.build(object, only_path: true)).to eq(path)
      end
    end

    context 'when passing a DesignManagement::Design' do
      let(:design) { build_stubbed(:design) }

      it 'uses the given ref and size in the URL' do
        url = subject.build(design, ref: 'feature', size: 'small')

        expect(url).to eq "#{Settings.gitlab['url']}/#{design.project.full_path}/-/design_management/designs/#{design.id}/feature/resized_image/small"
      end
    end
  end
end
