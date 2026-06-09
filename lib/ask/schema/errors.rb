# frozen_string_literal: true

module Ask
  class Schema
    # Base error class for all schema-related errors.
    class Error < StandardError; end

    # Raised when an invalid schema type is specified.
    class InvalidSchemaTypeError < Error
      # @param type [Symbol] The unrecognized type
      def initialize(type)
        super("Unknown schema type: #{type}")
      end
    end

    # Raised when an invalid type is passed to +array+ via the +:of+ option.
    class InvalidArrayTypeError < Error; end

    # Raised when an invalid type is passed to +object+ via the +:of+ option.
    class InvalidObjectTypeError < Error; end

    # Raised when a schema definition is structurally invalid.
    class InvalidSchemaError < Error; end

    # Raised when schema validation fails (e.g., circular references).
    class ValidationError < Error; end

    # Raised when a maximum or limit is exceeded.
    class LimitExceededError < Error; end
  end
end
