# frozen_string_literal: true

require_relative "dsl/schema_builders"
require_relative "dsl/primitive_types"
require_relative "dsl/complex_types"
require_relative "dsl/conditionals"
require_relative "dsl/utilities"

module Ask
  class Schema
    # Assembles all DSL modules into the Schema class.
    #
    # Includes {SchemaBuilders}, {PrimitiveTypes}, {ComplexTypes},
    # {Conditionals}, and {Utilities} to provide the full schema
    # definition DSL.
    module DSL
      include SchemaBuilders
      include PrimitiveTypes
      include ComplexTypes
      include Conditionals
      include Utilities
    end
  end
end
