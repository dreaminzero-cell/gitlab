# frozen_string_literal: true
module EE
  module SystemNotes
    module IssuablesService
      #
      # noteable_ref - Referenced noteable object
      #
      # Example Note text:
      #
      #   "marked this issue as related to gitlab-foss#9001"
      #
      # Returns the created Note object
      def relate_issue(noteable_ref)
        body = "marked this issue as related to #{noteable_ref.to_reference(noteable.project)}"

        create_note(NoteSummary.new(noteable, project, author, body, action: 'relate'))
      end

      #
      # noteable_ref - Referenced noteable object
      #
      # Example Note text:
      #
      #   "removed the relation with gitlab-foss#9001"
      #
      # Returns the created Note object
      def unrelate_issue(noteable_ref)
        body = "removed the relation with #{noteable_ref.to_reference(noteable.project)}"

        create_note(NoteSummary.new(noteable, project, author, body, action: 'unrelate'))
      end

      # Called when the weight of a Noteable is changed
      #
      # Example Note text:
      #
      #   "removed the weight"
      #
      #   "changed weight to 4"
      #
      # Returns the created Note object
      def change_weight_note
        body = noteable.weight ? "changed weight to **#{noteable.weight}**" : 'removed the weight'

        create_note(NoteSummary.new(noteable, project, author, body, action: 'weight'))
      end

      # Called when the health_status of an Issue is changed
      #
      # Example Note text:
      #
      #   "removed the health status"
      #
      #   "changed health status to at risk"
      #
      # Returns the created Note object
      def change_health_status_note
        health_status = noteable.health_status&.humanize(capitalize: false)
        body = health_status ? "changed health status to **#{health_status}**" : 'removed the health status'

        create_note(NoteSummary.new(noteable, project, author, body, action: 'health_status'))
      end
    end
  end
end
