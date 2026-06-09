# frozen_string_literal: true

module Ask
  class Schema
    # Validates schema definitions for structural issues such as circular
    # references in named definitions (`$defs`).
    #
    # Uses DFS-based topological sort with three-color marking (WHITE/GRAY/BLACK)
    # to detect cycles in definition dependency graphs.
    class Validator
      # Node states for DFS-based topological sort
      WHITE = :white  # No mark (unvisited)
      GRAY = :gray    # Temporary mark (currently being processed)
      BLACK = :black  # Permanent mark (completely processed)

      # @param schema_class [Class<Schema>] The schema class to validate
      def initialize(schema_class)
        @schema_class = schema_class
      end

      # Run all validations, raising on the first error.
      #
      # @return [nil] if the schema is valid
      # @raise [ValidationError] if a circular reference is detected
      def validate!
        validate_circular_references!
      end

      # Check if the schema is valid without raising.
      #
      # @return [Boolean]
      def valid?
        validate!
        true
      rescue ValidationError
        false
      end

      private

      # Detect circular references in $defs using DFS.
      def validate_circular_references!
        definitions = @schema_class.definitions
        return if definitions.empty?

        marks = Hash.new { WHITE }

        definitions.each_key do |node|
          visit(node, definitions, marks) if marks[node] == WHITE
        end
      end

      # DFS visit function with three-color marking.
      def visit(node, definitions, marks)
        return if marks[node] == BLACK

        raise ValidationError, "Circular reference detected involving '#{node}'" if marks[node] == GRAY

        marks[node] = GRAY

        definition = definitions[node]
        if definition && definition[:properties]
          definition[:properties].each_value do |property|
            extract_references(property).each do |adjacent_node|
              visit(adjacent_node, definitions, marks)
            end
          end
        end

        marks[node] = BLACK
      end

      # Recursively extract `$ref` references from a property definition.
      #
      # @param property [Hash, Array] A property definition or nested structure
      # @return [Array<Symbol>] Referenced definition names
      def extract_references(property)
        references = []

        case property
        when Hash
          if property["$ref"]
            ref_name = property["$ref"].split("/").last&.to_sym
            references << ref_name if ref_name
          else
            property.each_value do |value|
              references.concat(extract_references(value))
            end
          end
        when Array
          property.each do |item|
            references.concat(extract_references(item))
          end
        end

        references
      end
    end
  end
end
