# frozen_string_literal: true

module Ask
  class Schema
    module DSL
      # DSL methods for declaring primitive-type properties.
      module PrimitiveTypes
        # Declare a string property.
        # @param name [Symbol] Property name
        # @param description [String, nil] Property description
        # @param required [Boolean] Whether the property is required (default: true)
        # @param requires [Symbol, Array<Symbol>, nil] Dependent property requirements
        # @param options [Hash] Additional JSON Schema constraints (enum:, min_length:, pattern:, etc.)
        def string(name, description: nil, required: true, requires: nil, **options)
          add_property(name, string_schema(description: description, **options), required: required, requires: requires)
        end

        # Declare a number property.
        # @param name [Symbol] Property name
        # @param description [String, nil] Property description
        # @param required [Boolean] Whether the property is required (default: true)
        # @param requires [Symbol, Array<Symbol>, nil] Dependent property requirements
        # @param options [Hash] Additional JSON Schema constraints (minimum:, maximum:, etc.)
        def number(name, description: nil, required: true, requires: nil, **options)
          add_property(name, number_schema(description: description, **options), required: required, requires: requires)
        end

        # Declare an integer property.
        # @param name [Symbol] Property name
        # @param description [String, nil] Property description
        # @param required [Boolean] Whether the property is required (default: true)
        # @param requires [Symbol, Array<Symbol>, nil] Dependent property requirements
        # @param options [Hash] Additional JSON Schema constraints (minimum:, maximum:, etc.)
        def integer(name, description: nil, required: true, requires: nil, **options)
          add_property(name, integer_schema(description: description, **options), required: required, requires: requires)
        end

        # Declare a boolean property.
        # @param name [Symbol] Property name
        # @param description [String, nil] Property description
        # @param required [Boolean] Whether the property is required (default: true)
        # @param requires [Symbol, Array<Symbol>, nil] Dependent property requirements
        # @param options [Hash] Additional JSON Schema constraints
        def boolean(name, description: nil, required: true, requires: nil, **options)
          add_property(name, boolean_schema(description: description, **options), required: required, requires: requires)
        end

        # Declare a null property.
        # @param name [Symbol] Property name
        # @param description [String, nil] Property description
        # @param required [Boolean] Whether the property is required (default: true)
        # @param requires [Symbol, Array<Symbol>, nil] Dependent property requirements
        # @param options [Hash] Additional JSON Schema constraints
        def null(name, description: nil, required: true, requires: nil, **options)
          add_property(name, null_schema(description: description, **options), required: required, requires: requires)
        end
      end
    end
  end
end
