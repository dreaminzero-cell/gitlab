# frozen_string_literal: true

module Vulnerabilities
  class DismissService
    include Gitlab::Allowable

    FindingsDismissResult = Struct.new(:ok?, :finding, :message)

    attr_reader :vulnerability, :user

    def initialize(user, vulnerability)
      @user = user
      @vulnerability = vulnerability
      @project = vulnerability.project
    end

    def execute
      raise Gitlab::Access::AccessDeniedError unless can?(@user, :admin_vulnerability, @project)

      @vulnerability.transaction do
        result = dismiss_findings

        unless result.ok?
          handle_finding_dismissal_error(result.finding, result.message)
          raise ActiveRecord::Rollback
        end

        @vulnerability.update(state: Vulnerability.states[:dismissed], dismissed_by: @user, dismissed_at: Time.current)
      end

      create_vulnerability_note

      @vulnerability
    end

    private

    def feedback_service_for(finding)
      VulnerabilityFeedback::CreateService.new(@project, @user, feedback_params_for(finding))
    end

    def feedback_params_for(finding)
      {
        category: finding.report_type,
        feedback_type: 'dismissal',
        project_fingerprint: finding.project_fingerprint
      }
    end

    def dismiss_findings
      @vulnerability.findings.each do |finding|
        result = feedback_service_for(finding).execute

        return FindingsDismissResult.new(false, finding, result[:message]) if result[:status] == :error
      end

      FindingsDismissResult.new(true)
    end

    def handle_finding_dismissal_error(finding, message)
      @vulnerability.errors.add(
        :base,
        :finding_dismissal_error,
        message: _("failed to dismiss associated finding(id=%{finding_id}): %{message}") %
          {
            finding_id: finding.id,
            message: message
          })
    end

    def create_vulnerability_note
      return unless vulnerability.state_previously_changed?

      SystemNoteService.change_vulnerability_state(vulnerability, user, 'dismissed')
    end
  end
end
