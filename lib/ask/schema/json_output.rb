# frozen_string_literal: true

require "json"

module Ask
  class Schema
    # Generates JSON Schema output from a Schema class definition.
    module JsonOutput
      # Generate a hash representation of the JSON Schema.
      #
      # Validates the schema before generating output. The returned hash
      # includes +:name+, +:description+, and +:schema+ keys.
      #
      # @return [Hash] The JSON Schema representation
      # @raise [ValidationError] if the schema is invalid
      def to_json_schema
        validate!

        schema_hash = {
          type: "object",
          properties: self.class.properties,
          required: self.class.required_properties,
          additionalProperties: self.class.additional_properties
        }

        schema_hash[:strict] = self.class.strict unless self.class.strict.nil?

        schema_hash["$defs"] = self.class.definitions unless self.class.definitions.empty?

        self.class.send(:merge_conditions, schema_hash, self.class)

        {
          name: @name,
          description: @description || self.class.description,
          schema: schema_hash
        }
      end

      # Generate a pretty-printed JSON string of the schema.
      #
      # @return [String] Pretty-printed JSON
      # @raise [ValidationError] if the schema is invalid
      def to_json(*_args)
        validate!
        JSON.pretty_generate(to_json_schema)
      end
    end
  end
end
