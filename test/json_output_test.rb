# frozen_string_literal: true

require_relative "test_helper"

class JsonOutputTest < Minitest::Test
  def test_to_json_schema_has_name
    schema = Ask::Schema.create { string :name }
    output = schema.new("test").to_json_schema
    assert_equal "test", output[:name]
  end

  def test_to_json_schema_has_description
    schema = Ask::Schema.create { string :name }
    output = schema.new("test", description: "A test").to_json_schema
    assert_equal "A test", output[:description]
  end

  def test_to_json_schema_has_schema_key
    schema = Ask::Schema.create { string :name }
    output = schema.new("test").to_json_schema
    assert output.key?(:schema)
  end

  def test_to_json_schema_includes_strict
    schema = Ask::Schema.create { string :name }
    output = schema.new("test").to_json_schema
    assert_equal true, output.dig(:schema, :strict)
  end

  def test_to_json_schema_includes_additional_properties
    schema = Ask::Schema.create { string :name }
    output = schema.new("test").to_json_schema
    assert_equal false, output.dig(:schema, :additionalProperties)
  end

  def test_to_json_returns_string
    schema = Ask::Schema.create { string :name }
    json = schema.new("test").to_json
    assert_kind_of String, json
  end

  def test_to_json_is_valid_json
    schema = Ask::Schema.create { string :name }
    json = schema.new("test").to_json
    parsed = JSON.parse(json)
    assert parsed.is_a?(Hash)
  end

  def test_to_json_includes_defs_when_present
    schema = Ask::Schema.create do
      define(:address) { string :street }
    end
    output = schema.new("test").to_json_schema
    assert output.dig(:schema, "$defs").key?(:address)
  end

  def test_to_json_omits_defs_when_empty
    schema = Ask::Schema.create { string :name }
    output = schema.new("test").to_json_schema
    refute output.dig(:schema, "$defs")
  end

  def test_respond_to_missing_for_dsl_methods
    schema = Ask::Schema.create { string :name }

    instance = schema.new("test")
    assert instance.respond_to?(:string)
    assert instance.respond_to?(:number)
    assert instance.respond_to?(:array)
    assert instance.respond_to?(:object)
    assert instance.respond_to?(:any_of)
    assert instance.respond_to?(:one_of)
    assert instance.respond_to?(:null)
  end

  def test_helpers_module
    assert Ask::Schema::Helpers.instance_methods.include?(:schema)
  end
end
