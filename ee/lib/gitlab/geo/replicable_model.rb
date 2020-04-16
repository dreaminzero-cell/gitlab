# frozen_string_literal: true

module Gitlab
  module Geo
    module ReplicableModel
      extend ActiveSupport::Concern
      include Checksummable

      included do
        # If this hook turns out not to apply to all Models, perhaps we should extract a `ReplicableBlobModel`
        after_create_commit -> { replicator.handle_after_create_commit if replicator.respond_to?(:handle_after_create_commit) }
      end

      class_methods do
        # Associate current model with specified replicator
        #
        # @param [Gitlab::Geo::Replicator] klass
        def with_replicator(klass)
          raise ArgumentError, 'Must be a class inheriting from Gitlab::Geo::Replicator' unless klass < ::Gitlab::Geo::Replicator

          class_eval <<-RUBY, __FILE__, __LINE__ + 1
            define_method :replicator do
              @_replicator ||= klass.new(model_record: self)
            end
          RUBY
        end
      end

      # Geo Replicator
      #
      # @abstract
      # @return [Gitlab::Geo::Replicator]
      def replicator
        raise NotImplementedError, 'There is no Replicator defined for this model'
      end

      # Clear model verification checksum and force recalculation
      def calculate_checksum!
        self.verification_checksum = nil

        return unless needs_checksum?

        self.verification_checksum = self.class.hexdigest(file.path)
      end

      # Checks whether model needs checksum to be performed
      #
      # Conditions:
      # - No checksum is present
      # - It's capable of generating a checksum of itself
      #
      # @return [Boolean]
      def needs_checksum?
        verification_checksum.nil? && checksummable?
      end

      # Return whether its capable of generating a checksum of itself
      #
      # @return [Boolean] whether it can generate a checksum
      def checksummable?
        local? && file_exist?
      end

      # This checks for existence of the file on storage
      #
      # @return [Boolean] whether the file exists on storage
      def file_exist?
        if local?
          File.exist?(file.path)
        else
          file.exists?
        end
      end
    end
  end
end
