# frozen_string_literal: true

require_relative "ask/schema/version"
require_relative "ask/schema/errors"
require_relative "ask/schema/helpers"
require_relative "ask/schema/validator"
require_relative "ask/schema/dsl"
require_relative "ask/schema/json_output"
require "json"

module Ask
  # Build standards-compliant JSON Schema documents using a compact Ruby DSL.
  #
  # Supports both block-based and class-based usage patterns, with full support
  # for JSON Schema Draft 07/2020-12 features including composition, conditionals,
  # definitions, and validation.
  #
  # @example Block-based DSL
  #   schema = Ask::Schema.create do
  #     string :name, description: "Full name"
  #     integer :age, minimum: 0
  #   end
  #   schema.new("user").to_json_schema
  #
  # @example Class-based DSL
  #   class Product < Ask::Schema
  #     string :name, description: "Product name"
  #     number :price
  #   end
  #   Product.new("product").to_json_schema
  class Schema
    extend DSL
    include JsonOutput

    # Primitive JSON Schema types available in the DSL.
    PRIMITIVE_TYPES = %i[string number integer boolean null].freeze

    class << self
      # Create a new Schema subclass from a DSL block.
      #
      # @param block [Proc] DSL block with type definitions
      # @return [Class<Schema>] A dynamically-created Schema subclass
      #
      # @example
      #   schema = Ask::Schema.create do
      #     string :name
      #     integer :age
      #   end
      def create(&block)
        schema_class = Class.new(Schema)
        schema_class.class_eval(&block)
        schema_class
      end

      # Properties defined on this schema class (inheritable).
      #
      # @return [Hash{Symbol => Hash}] Property definitions keyed by name
      def properties
        @properties ||= {}
      end

      # Required property names for this schema class (inheritable).
      #
      # @return [Array<Symbol>] Required property names
      def required_properties
        @required_properties ||= []
      end

      # Named sub-schema definitions for `$defs`.
      #
      # @return [Hash{Symbol => Hash}] Named definitions keyed by symbol
      def definitions
        @definitions ||= {}
      end

      # Set or get the schema name used in JSON output.
      #
      # @param name [String, nil] The schema name
      # @return [String, nil] The current schema name
      def name(name = nil)
        @schema_name = name if name
        return @schema_name if defined?(@schema_name)

        super()
      end

      # Set or get the schema description used in JSON output.
      #
      # @param description [String, nil] The schema description
      # @return [String, nil] The current description
      def description(description = nil)
        @description = description if description
        @description
      end

      # Set or get whether additional (undeclared) properties are allowed.
      #
      # @param value [Boolean, nil] True to allow additional properties
      # @return [Boolean] Defaults to +false+
      def additional_properties(value = nil)
        return @additional_properties ||= false if value.nil?

        @additional_properties = value
      end

      # Set or get strict mode for the schema.
      #
      # When strict, the schema includes `"strict": true` in output.
      #
      # @param args [Boolean, nil] The strict mode value
      # @return [Boolean] Defaults to +true+
      def strict(*args)
        if args.empty?
          instance_variable_defined?(:@strict) ? @strict : true
        else
          @strict = args.first
        end
      end

      # Validate the schema definition, raising on circular references or other errors.
      #
      # @return [nil] if the schema is valid
      # @raise [ValidationError] if the schema has circular references
      def validate!
        validator = Validator.new(self)
        validator.validate!
      end

      # Check if the schema definition is valid.
      #
      # @return [Boolean] true if the schema has no validation errors
      def valid?
        validator = Validator.new(self)
        validator.valid?
      end
    end

    # Create a new schema instance.
    #
    # @param name [String, nil] Instance name (overrides class name in JSON output)
    # @param description [String, nil] Instance description (overrides class description)
    def initialize(name = nil, description: nil)
      @name = name || self.class.name || "Schema"
      @description = description
    end

    # Validate this schema instance.
    #
    # @return [nil] if valid
    # @raise [ValidationError] if invalid
    def validate!
      self.class.validate!
    end

    # Check if this schema instance is valid.
    #
    # @return [Boolean]
    def valid?
      self.class.valid?
    end

    # Delegate DSL methods (string, number, integer, etc.) to the class level.
    def method_missing(method_name, ...)
      if respond_to_missing?(method_name)
        self.class.send(method_name, ...)
      else
        super
      end
    end

    # Check if a method can be delegated to the class level.
    def respond_to_missing?(method_name, include_private = false)
      %i[string number integer boolean array object any_of one_of null].include?(method_name) || super
    end
  end
end
