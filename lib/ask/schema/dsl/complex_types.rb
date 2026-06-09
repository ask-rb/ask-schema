# frozen_string_literal: true

module Ask
  class Schema
    module DSL
      # DSL methods for declaring complex (non-primitive) property types.
      module ComplexTypes
        # Declare an object property with inline or referenced sub-schema.
        # @param name [Symbol] Property name
        # @param description [String, nil] Property description
        # @param required [Boolean] Whether the property is required (default: true)
        # @param requires [Symbol, Array<Symbol>, nil] Dependent property requirements
        # @param options [Hash] Additional options (of:, reference:)
        # @param block [Proc] Inline property definitions
        def object(name, description: nil, required: true, requires: nil, **options, &block)
          add_property(name, object_schema(description: description, **options, &block), required: required, requires: requires)
        end

        # Declare an array property.
        # @param name [Symbol] Property name
        # @param description [String, nil] Property description
        # @param required [Boolean] Whether the property is required (default: true)
        # @param requires [Symbol, Array<Symbol>, nil] Dependent property requirements
        # @param options [Hash] Additional options (of:, min_items:, max_items:)
        # @param block [Proc] Block for complex item definitions
        def array(name, description: nil, required: true, requires: nil, **options, &block)
          add_property(name, array_schema(description: description, **options, &block), required: required, requires: requires)
        end

        # Declare a property accepting any of the listed schemas.
        # @param name [Symbol] Property name
        # @param description [String, nil] Property description
        # @param required [Boolean] Whether the property is required (default: true)
        # @param requires [Symbol, Array<Symbol>, nil] Dependent property requirements
        # @param options [Hash] Additional options
        # @param block [Proc] Block listing alternative schemas
        def any_of(name, description: nil, required: true, requires: nil, **options, &block)
          add_property(name, any_of_schema(description: description, **options, &block), required: required, requires: requires)
        end

        # Declare a property accepting exactly one of the listed schemas.
        # @param name [Symbol] Property name
        # @param description [String, nil] Property description
        # @param required [Boolean] Whether the property is required (default: true)
        # @param requires [Symbol, Array<Symbol>, nil] Dependent property requirements
        # @param options [Hash] Additional options
        # @param block [Proc] Block listing alternative schemas
        def one_of(name, description: nil, required: true, requires: nil, **options, &block)
          add_property(name, one_of_schema(description: description, **options, &block), required: required, requires: requires)
        end

        # Declare an optional (nullable) property using +anyOf+ with +null+.
        #
        # @example
        #   optional :nickname do
        #     string
        #   end
        #   # Produces: anyOf: [{ type: "string" }, { type: "null" }]
        #
        # @param name [Symbol] Property name
        # @param description [String, nil] Property description
        # @param block [Proc] Block defining the non-null type
        def optional(name, description: nil, &block)
          any_of(name, description: description) do
            instance_eval(&block)
            null
          end
        end
      end
    end
  end
end
