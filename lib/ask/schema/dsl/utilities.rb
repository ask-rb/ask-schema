# frozen_string_literal: true

module Ask
  class Schema
    module DSL
      # Utility methods for schema definitions, references, and property registration.
      module Utilities
        # Define a named sub-schema for reuse via {reference}.
        #
        # Named definitions appear in the output under `$defs`.
        #
        # @example
        #   define(:address) do
        #     string :street
        #     string :city
        #   end
        #
        # @param name [Symbol] The definition name (used in $ref)
        # @param block [Proc] DSL block for the sub-schema properties
        def define(name, &)
          sub_schema = Class.new(Schema)
          sub_schema.class_eval(&)

          schema = {
            type: "object",
            properties: sub_schema.properties,
            required: sub_schema.required_properties,
            additionalProperties: sub_schema.additional_properties
          }

          merge_conditions(schema, sub_schema)

          definitions[name] = schema
        end

        # Create a `$ref` reference to a named definition or root.
        #
        # Use with +object+ or +array+ via the +:of+ option, or standalone
        # to produce a reference hash.
        #
        # @example
        #   reference(:address)  # => { "$ref" => "#/$defs/address" }
        #   reference(:root)     # => { "$ref" => "#" }
        #
        # @param schema_name [Symbol] The definition name, or +:root+ for root reference
        # @return [Hash{"$ref" => String}] The reference
        def reference(schema_name)
          if schema_name == :root
            {"$ref" => "#"}
          else
            {"$ref" => "#/$defs/#{schema_name}"}
          end
        end

        private

        # Register a property on the schema class.
        #
        # @param name [Symbol] Property name
        # @param definition [Hash] JSON Schema fragment for the property
        # @param required [Boolean] Whether the property is required
        # @param requires [Symbol, Array<Symbol>, nil] Dependent property requirements
        # @return [nil]
        def add_property(name, definition, required:, requires: nil)
          property_name = name.to_sym

          properties[property_name] = definition
          if required
            required_properties << property_name unless required_properties.include?(property_name)
          else
            required_properties.delete(property_name)
          end

          if requires
            builder = ConditionalBuilder.new
            builder.requires(*Array(requires))
            dependencies[name.to_s] = builder
          end

          nil
        end

        # Check if a type is a primitive JSON Schema type.
        # @param type [Symbol] The type to check
        # @return [Boolean]
        def primitive_type?(type)
          type.is_a?(Symbol) && PRIMITIVE_TYPES.include?(type)
        end

        # Check if a value is a Schema class or instance.
        # @param type [Object] The value to check
        # @return [Boolean]
        def schema_class?(type)
          (type.is_a?(Class) && type < Schema) || type.is_a?(Schema)
        end
      end
    end
  end
end
