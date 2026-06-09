# frozen_string_literal: true

module Ask
  class Schema
    module DSL
      # Core schema builders that generate JSON Schema fragments for each type.
      #
      # Each method returns a Hash representing a JSON Schema fragment for
      # the given type, with all specified constraints.
      module SchemaBuilders
        # Build a string schema fragment.
        # @param description [String, nil] Property description
        # @param enum [Array<String>, nil] Allowed values
        # @param min_length [Integer, nil] Minimum string length
        # @param max_length [Integer, nil] Maximum string length
        # @param pattern [String, nil] Regex pattern for validation
        # @param format [String, nil] String format (e.g., "email", "uri")
        # @return [Hash] JSON Schema fragment
        def string_schema(description: nil, enum: nil, min_length: nil, max_length: nil, pattern: nil, format: nil)
          {
            type: "string",
            enum: enum,
            description: description,
            minLength: min_length,
            maxLength: max_length,
            pattern: pattern,
            format: format
          }.compact
        end

        # Build a number schema fragment.
        # @param description [String, nil] Property description
        # @param minimum [Numeric, nil] Minimum value
        # @param maximum [Numeric, nil] Maximum value
        # @param multiple_of [Numeric, nil] Value must be multiple of this
        # @param enum [Array<Numeric>, nil] Allowed values
        # @return [Hash] JSON Schema fragment
        def number_schema(description: nil, minimum: nil, maximum: nil, multiple_of: nil, enum: nil)
          {
            type: "number",
            description: description,
            minimum: minimum,
            maximum: maximum,
            multipleOf: multiple_of,
            enum: enum
          }.compact
        end

        # Build an integer schema fragment.
        # @param description [String, nil] Property description
        # @param minimum [Integer, nil] Minimum value
        # @param maximum [Integer, nil] Maximum value
        # @param multiple_of [Integer, nil] Value must be multiple of this
        # @param enum [Array<Integer>, nil] Allowed values
        # @return [Hash] JSON Schema fragment
        def integer_schema(description: nil, minimum: nil, maximum: nil, multiple_of: nil, enum: nil)
          {
            type: "integer",
            description: description,
            minimum: minimum,
            maximum: maximum,
            multipleOf: multiple_of,
            enum: enum
          }.compact
        end

        # Build a boolean schema fragment.
        # @param description [String, nil] Property description
        # @return [Hash] JSON Schema fragment
        def boolean_schema(description: nil)
          {type: "boolean", description: description}.compact
        end

        # Build a null schema fragment.
        # @param description [String, nil] Property description
        # @return [Hash] JSON Schema fragment
        def null_schema(description: nil)
          {type: "null", description: description}.compact
        end

        # Build an object schema fragment, either inline or via reference.
        #
        # When called with a block, defines properties inline.
        # When called with +:of+, creates a reference to a named definition.
        # When called with +reference:+ (deprecated), creates a reference.
        #
        # @param description [String, nil] Property description
        # @param of [Symbol, Class, nil] Reference target (definition name or Schema class)
        # @param reference [Symbol, nil] Deprecated: use +of+ instead
        # @param block [Proc] Inline property definitions
        # @return [Hash] JSON Schema fragment
        def object_schema(description: nil, of: nil, reference: nil, &block)
          if reference
            warn "[DEPRECATION] The `reference` option will be deprecated. Please use `of` instead."
            of = reference
          end

          if of
            determine_object_reference(of, description)
          else
            sub_schema = Class.new(Schema)
            result = sub_schema.class_eval(&block)

            if result.is_a?(Hash) && result["$ref"] && sub_schema.properties.empty?
              result.merge(description ? {description: description} : {})
            elsif schema_class?(result) && sub_schema.properties.empty?
              schema_class_to_inline_schema(result).merge(description ? {description: description} : {})
            else
              schema = {
                type: "object",
                properties: sub_schema.properties,
                required: sub_schema.required_properties,
                additionalProperties: sub_schema.additional_properties,
                description: description
              }.compact

              merge_conditions(schema, sub_schema)
            end
          end
        end

        # Build an array schema fragment.
        #
        # Items can be specified inline via a block, or via the +:of+ option
        # for simple types, references, or Schema classes.
        #
        # @param description [String, nil] Property description
        # @param of [Symbol, Class, nil] Items type (:string, :number, a definition name, or Schema class)
        # @param min_items [Integer, nil] Minimum number of items
        # @param max_items [Integer, nil] Maximum number of items
        # @param block [Proc] Block for complex item schemas
        # @return [Hash] JSON Schema fragment
        def array_schema(description: nil, of: nil, min_items: nil, max_items: nil, &block)
          items = determine_array_items(of, &block)

          {
            type: "array",
            description: description,
            items: items,
            minItems: min_items,
            maxItems: max_items
          }.compact
        end

        # Build an +anyOf+ schema fragment.
        #
        # @param description [String, nil] Property description
        # @param block [Proc] Block listing alternative schemas
        # @return [Hash] JSON Schema fragment
        def any_of_schema(description: nil, &block)
          schemas = collect_schemas_from_block(&block)

          {
            description: description,
            anyOf: schemas
          }.compact
        end

        # Build a +oneOf+ schema fragment.
        #
        # @param description [String, nil] Property description
        # @param block [Proc] Block listing alternative schemas
        # @return [Hash] JSON Schema fragment
        def one_of_schema(description: nil, &block)
          schemas = collect_schemas_from_block(&block)

          {
            description: description,
            oneOf: schemas
          }.compact
        end

        private

        # Determine the items schema for an array.
        def determine_array_items(of, &)
          return collect_schemas_from_block(&).first if block_given?
          return send("#{of}_schema") if primitive_type?(of)
          return reference(of) if of.is_a?(Symbol)
          return schema_class_to_inline_schema(of) if schema_class?(of)

          raise InvalidArrayTypeError, "Invalid array type: #{of.inspect}. Must be a primitive type (:string, :number, etc.), a symbol reference, a Schema class, or a Schema instance."
        end

        # Determine the target of an object reference.
        def determine_object_reference(of, description = nil)
          result = case of
                   when Symbol
                     reference(of)
                   when Class
                     raise InvalidObjectTypeError, "Invalid object type: #{of.inspect}. Class must inherit from Ask::Schema." unless schema_class?(of)

                     schema_class_to_inline_schema(of)
                   else
                     raise InvalidObjectTypeError, "Invalid object type: #{of.inspect}. Must be a symbol reference, a Schema class, or a Schema instance." unless schema_class?(of)

                     schema_class_to_inline_schema(of)
                   end

          description ? result.merge(description: description) : result
        end

        # Collect schemas from a composition block (any_of, one_of).
        def collect_schemas_from_block(&block)
          schemas = []
          schema_builder = self

          context = Object.new

          schema_builder.methods.grep(/_schema$/).each do |schema_method|
            type_name = schema_method.to_s.sub(/_schema$/, "")

            context.define_singleton_method(type_name) do |_name = nil, **options, &blk|
              schemas << schema_builder.send(schema_method, **options, &blk)
            end
          end

          context.define_singleton_method(:const_missing) do |name|
            const_get(name) if const_defined?(name)
          end

          context.instance_eval(&block)
          schemas
        end

        # Convert a Schema class (or instance) into an inline object schema hash.
        def schema_class_to_inline_schema(schema_class_or_instance)
          schema_class = if schema_class_or_instance.is_a?(Class)
                           schema_class_or_instance
                         else
                           schema_class_or_instance.class
                         end

          {
            type: "object",
            properties: schema_class.properties,
            required: schema_class.required_properties,
            additionalProperties: schema_class.additional_properties
          }.tap do |schema|
            description = if schema_class_or_instance.is_a?(Class)
                            schema_class.description
                          else
                            schema_class_or_instance.instance_variable_get(:@description) || schema_class.description
                          end

            schema[:description] = description if description

            merge_conditions(schema, schema_class)
          end
        end
      end
    end
  end
end
