# frozen_string_literal: true

module QA
  context 'Plan', :reliable do
    shared_examples 'issues analytics page' do
      let(:issue) do
        Resource::Issue.fabricate_via_api!
      end

      before do
        Flow::Login.sign_in
      end

      it 'displays a graph' do
        page.visit(path)

        EE::Page::Group::IssuesAnalytics.perform do |issues_analytics|
          expect(issues_analytics.graph).to be_visible
        end
      end
    end

    describe 'Group level issues analytics' do
      it_behaves_like 'issues analytics page' do
        let(:path) { page.visit("#{issue.project.group.web_url}/-/issues_analytics") }
      end
    end

    describe 'Project level issues analytics' do
      it_behaves_like 'issues analytics page' do
        let(:path) { page.visit("#{issue.project.web_url}/-/analytics/issues_analytics") }
      end
    end
  end
end
