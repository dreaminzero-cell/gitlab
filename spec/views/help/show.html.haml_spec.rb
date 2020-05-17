# frozen_string_literal: true

require 'spec_helper'

describe 'help/show' do
  describe 'Markdown rendering' do
    before do
      assign(:path, 'ssh/README')
      assign(:markdown, 'Welcome to [GitLab](https://about.gitlab.com/) Documentation.')
    end

    it 'renders Markdown' do
      render

      expect(rendered).to have_link('GitLab', href: 'https://about.gitlab.com/')
    end
  end
end
