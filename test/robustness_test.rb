# frozen_string_literal: true

require_relative "test_helper"

class RobustnessTest < Minitest::Test
  def test_no_properties
    schema = Ask::Schema.create { }
    assert schema
    assert schema.valid?
  end

  def test_extra_properties_not_restricted_by_default
    schema = Ask::Schema.create do
      string(:name)
    end
    assert schema.valid?
    assert schema.strict
  end

  def test_numeric_types
    schema = Ask::Schema.create do
      integer(:count)
      number(:price)
    end
    assert schema.valid?
    assert schema.properties.key?(:count)
    assert schema.properties.key?(:price)
  end

  def test_array_type
    schema = Ask::Schema.create do
      array(:tags, of: :string)
    end
    assert schema.valid?
    assert schema.properties.key?(:tags)
  end

  def test_boolean_type
    schema = Ask::Schema.create do
      boolean(:active)
    end
    assert schema.valid?
  end

  def test_enum_values
    schema = Ask::Schema.create do
      string(:color, enum: %w[red blue green])
    end
    assert schema.valid?
    assert_includes schema.properties[:color][:enum], "red"
  end

  def test_nested_object
    schema = Ask::Schema.create do
      object(:outer) do
        string(:inner)
      end
    end
    assert schema.valid?
  end

  def test_json_output_included_in_schema
    schema = Ask::Schema.create { string(:name) }
    instance = schema.new("test")
    assert_respond_to instance, :to_json_schema
    assert_respond_to instance, :to_json
  end

  def test_to_json_schema_returns_hash
    schema = Ask::Schema.create do
      string(:name)
      integer(:age)
    end
    instance = schema.new("Person")
    json_schema = instance.to_json_schema
    assert_equal "object", json_schema.dig(:schema, :type)
    assert json_schema.dig(:schema, :properties).key?(:name)
    assert json_schema.dig(:schema, :properties).key?(:age)
  end

  def test_empty_enum_list
    schema = Ask::Schema.create do
      string(:color, enum: [])
    end
    assert schema.valid?
    assert_empty schema.properties[:color][:enum]
  end

  def test_multiple_schemas_dont_interfere
    s1 = Ask::Schema.create { string(:a) }
    s2 = Ask::Schema.create { integer(:b) }
    assert s1.properties.key?(:a)
    assert s2.properties.key?(:b)
    refute s1.properties.key?(:b)
    refute s2.properties.key?(:a)
  end
end
