# frozen_string_literal: true

require_relative "test_helper"

class SchemaTest < Minitest::Test
  def test_version_is_defined
    assert_equal "0.1.0", Ask::Schema::VERSION
  end

  def test_block_based_dsl_creates_schema_class
    schema = Ask::Schema.create do
      string :name, description: "The name"
    end

    assert_kind_of Class, schema
    assert schema < Ask::Schema
  end

  def test_block_based_dsl_adds_properties
    schema = Ask::Schema.create do
      string :name, description: "The name"
      integer :age, description: "Age in years"
    end

    assert_equal %i[age name], schema.properties.keys.sort
  end

  def test_required_properties_default_to_true
    schema = Ask::Schema.create do
      string :name
    end

    assert_includes schema.required_properties, :name
  end

  def test_optional_properties
    schema = Ask::Schema.create do
      string :name
      string :nickname, required: false
    end

    assert_includes schema.required_properties, :name
    refute_includes schema.required_properties, :nickname
  end

  def test_to_json_schema_returns_correct_structure
    schema = Ask::Schema.create do
      string :name
    end

    instance = schema.new("test", description: "A test")
    output = instance.to_json_schema

    assert_equal "test", output[:name]
    assert_equal "A test", output[:description]
    assert_equal "object", output.dig(:schema, :type)
    assert output.dig(:schema, :properties).key?(:name)
  end

  def test_to_json_returns_valid_json
    schema = Ask::Schema.create do
      string :name
    end

    json = schema.new("test").to_json
    parsed = JSON.parse(json)

    assert_equal "test", parsed["name"]
    assert_equal "object", parsed.dig("schema", "type")
  end
end
