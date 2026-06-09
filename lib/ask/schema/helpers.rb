# frozen_string_literal: true

module Ask
  class Schema
    # Convenience helpers for creating schemas in a top-level context.
    module Helpers
      # Create a new schema instance using a DSL block.
      #
      # @param name [String, nil] Schema name
      # @param description [String, nil] Schema description
      # @param block [Proc] DSL block with type definitions
      # @return [Schema] A new schema instance
      def schema(name = nil, description: nil, &block)
        schema_class = Ask::Schema.create(&block)
        schema_class.new(name, description: description)
      end
    end
  end
end
