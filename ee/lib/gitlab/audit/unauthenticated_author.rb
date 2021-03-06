# frozen_string_literal: true

module Gitlab
  module Audit
    class UnauthenticatedAuthor < Gitlab::Audit::NullAuthor
      def initialize(name: nil)
        super(id: -1, name: name)
      end

      # Events that are authored by unathenticated users, should be
      # shown as authored by `An unauthenticated user` in the UI.
      def name
        @name || 'An unauthenticated user'
      end
    end
  end
end
