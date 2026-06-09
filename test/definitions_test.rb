# frozen_string_literal: true

require_relative "test_helper"

class DefinitionsTest < Minitest::Test
  def test_define_creates_named_definition
    schema = Ask::Schema.create do
      define(:address) do
        string :street
        string :city
        string :zip
      end
    end

    assert schema.definitions.key?(:address)
    assert_equal "object", schema.definitions[:address][:type]
  end

  def test_reference_creates_ref
    schema = Ask::Schema.create do
      define(:address) do
        string :street
      end
      object :home, of: :address
    end

    prop = schema.properties[:home]
    assert_equal "#/$defs/address", prop["$ref"]
  end

  def test_reference_root
    schema = Ask::Schema.create do
      reference(:root)
    end

    # Using reference at top level doesn't make sense, but ensure it works
    ref = schema.send(:reference, :root)
    assert_equal "#", ref["$ref"]
  end

  def test_definitions_in_json_schema
    schema = Ask::Schema.create do
      define(:address) do
        string :street
      end
    end

    output = schema.new("test").to_json_schema
    assert output.dig(:schema, "$defs").key?(:address)
  end

  def test_inline_object_schema
    schema = Ask::Schema.create do
      object :address do
        string :street
        string :city
      end
    end

    prop = schema.properties[:address]
    assert_equal "object", prop[:type]
    assert prop[:properties].key?(:street)
    assert prop[:properties].key?(:city)
  end

  def test_object_with_of_reference
    schema = Ask::Schema.create do
      define(:address) do
        string :street
      end
      object :billing, of: :address
    end

    assert_equal "#/$defs/address", schema.properties[:billing]["$ref"]
  end
end
