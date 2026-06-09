# frozen_string_literal: true

module Ask
  class Schema
    module DSL
      # Conditional schema features: +if/then/else+, +dependentRequired+,
      # and +dependentSchemas+ for JSON Schema conditional validation.
      module Conditionals
        # Collection of conditionals (if/then/else) defined on this schema.
        # @return [Array<Hash>] The conditions
        def conditions
          @conditions ||= []
        end

        # Collection of dependencies (dependentRequired/dependentSchemas) defined.
        # @return [Hash{String => ConditionalBuilder}] The dependencies
        def dependencies
          @dependencies ||= {}
        end

        # Declare that a property has dependencies on other properties.
        #
        # @example
        #   dependent :shipping_address do
        #     requires :name, :street, :city
        #   end
        #
        # @param property [Symbol] The property that has dependencies
        # @param block [Proc] Block declaring requirements via +requires+ and +validates+
        def dependent(property, &block)
          builder = ConditionalBuilder.new
          builder.instance_eval(&block)

          dependencies[property.to_s] = builder
        end

        # Declare a conditional (if/then/else) constraint.
        #
        # Values are automatically coerced: scalars become +const+, arrays become
        # +enum+, and Regexps become +pattern+.
        #
        # @example
        #   given(age: 18) do
        #     requires :license_number
        #     otherwise do
        #       requires :guardian_name
        #     end
        #   end
        #
        # @param properties [Hash{Symbol => Object}] Property conditions
        # @param block [Proc] Block declaring then/else requirements
        # @raise [ArgumentError] If no conditions are provided
        def given(**properties, &block)
          raise ArgumentError, "given requires at least one property condition" if properties.empty?

          if_schema = {
            properties: properties.transform_keys(&:to_s).transform_values { |v| coerce_condition(v) },
            required: properties.keys.map(&:to_s)
          }

          then_builder = ConditionalBuilder.new
          else_builder = ConditionalBuilder.new

          context = ConditionalContext.new(then_builder, else_builder)
          context.instance_eval(&block)

          condition = {if: if_schema, then: then_builder.to_schema}
          condition[:else] = else_builder.to_schema unless else_builder.empty?

          conditions << condition
        end

        private

        # Merge any conditions and dependencies from a sub-schema into the schema hash.
        def merge_conditions(schema, schema_class)
          if schema_class.respond_to?(:conditions) && schema_class.conditions.any?
            if schema_class.conditions.length == 1
              schema.merge!(schema_class.conditions.first)
            else
              schema[:allOf] = schema_class.conditions
            end
          end

          if schema_class.respond_to?(:dependencies) && schema_class.dependencies.any?
            dependent_required = {}
            dependent_schemas = {}

            schema_class.dependencies.each do |property, builder|
              if builder.validations_empty?
                dependent_required[property] = builder.required_fields
              else
                dependent_schemas[property] = builder.to_schema
              end
            end

            schema[:dependentRequired] = dependent_required if dependent_required.any?
            schema[:dependentSchemas] = dependent_schemas if dependent_schemas.any?
          end

          schema
        end

        # Coerce a Ruby value into a JSON Schema condition.
        # @param value [Object] The condition value
        # @return [Hash] JSON Schema condition fragment
        def coerce_condition(value)
          case value
          when Array then {enum: value}
          when Regexp then {pattern: value.source}
          when Hash then value
          else {const: value}
          end
        end
      end

      # Execution context for +given+ blocks, providing +requires+, +validates+,
      # and +otherwise+ DSL methods.
      class ConditionalContext
        # @param then_builder [ConditionalBuilder] Builder for the "then" clause
        # @param else_builder [ConditionalBuilder] Builder for the "else" clause
        def initialize(then_builder, else_builder)
          @then_builder = then_builder
          @else_builder = else_builder
        end

        # Mark fields as required when the condition is met.
        # @param fields [Array<Symbol>] Field names to require
        def requires(*fields)
          @then_builder.requires(*fields)
        end

        # Add validation constraints for a field.
        # @param field [Symbol] Field name
        # @param options [Hash] Validation constraints
        # @option options [Symbol] :type Expected JSON type
        # @option options [Object] :const Expected constant value
        # @option options [Array] :enum Allowed values
        # @option options [Object] :not_value Disallowed value (maps to +not+)
        # @option options [Integer] :min_length Minimum string length
        # @option options [Integer] :max_length Maximum string length
        # @option options [String, Regexp] :pattern Regex pattern
        # @option options [Numeric] :minimum Minimum number
        # @option options [Numeric] :maximum Maximum number
        def validates(field, **options)
          @then_builder.validates(field, **options)
        end

        # Define the "else" clause for when the condition is not met.
        # @param block [Proc] Block declaring requirements
        def otherwise(&block)
          @else_builder.instance_eval(&block)
        end
      end

      # Builder for collecting requirements and validations within a conditional clause.
      class ConditionalBuilder
        # Mark fields as required.
        # @param fields [Array<Symbol, String>] Field names
        def requires(*fields)
          required.concat(fields.map(&:to_s))
        end

        # Map of validated option names to JSON Schema key names.
        VALIDATES_KEY_MAP = {
          type: :type,
          const: :const,
          enum: :enum,
          not_value: :not,
          min_length: :minLength,
          max_length: :maxLength,
          pattern: :pattern,
          minimum: :minimum,
          maximum: :maximum
        }.freeze

        # Add validation constraints for a field.
        #
        # @param field [Symbol] Field name
        # @param options [Hash] Validation constraints (see {ConditionalContext#validates})
        # @raise [ArgumentError] If an unknown option is provided
        def validates(field, **options)
          constraints = {}

          options.each do |key, value|
            schema_key = VALIDATES_KEY_MAP[key]
            raise ArgumentError, "unknown validates option: #{key.inspect}" unless schema_key

            case key
            when :type then constraints[:type] = value.to_s
            when :not_value then constraints[:not] = {const: value}
            when :pattern then constraints[:pattern] = value.is_a?(Regexp) ? value.source : value
            else constraints[schema_key] = value
            end
          end

          validations[field.to_s] = constraints
        end

        # Convert to a JSON Schema fragment.
        # @return [Hash] Schema fragment with +required+ and +properties+
        def to_schema
          schema = {}

          schema[:required] = required if required.any?
          schema[:properties] = validations if validations.any?

          schema
        end

        # Check if the builder has no requirements or validations.
        # @return [Boolean]
        def empty?
          required.empty? && validations.empty?
        end

        # Get the required field names (duped).
        # @return [Array<String>]
        def required_fields
          required.dup
        end

        # Check if no validations have been defined.
        # @return [Boolean]
        def validations_empty?
          validations.empty?
        end

        private

        # @return [Array<String>] Accumulated required fields
        def required
          @required ||= []
        end

        # @return [Hash{String => Hash}] Accumulated field validations
        def validations
          @validations ||= {}
        end
      end
    end
  end
end
