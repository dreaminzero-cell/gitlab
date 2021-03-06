# frozen_string_literal: true

module StatusPage
  # Only comments with this emoji are visible.
  # This filter will change once we have confidential notes.
  # See https://gitlab.com/gitlab-org/gitlab/issues/207468
  AWARD_EMOJI = 'microphone'

  # Convenient method to trigger a status page update.
  def self.trigger_publish(project, user, triggered_by)
    TriggerPublishService.new(project, user, triggered_by).execute
  end
end
