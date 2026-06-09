# frozen_string_literal: true

require_relative "test_helper"

class ClassBasedTest < Minitest::Test
  class Product < Ask::Schema
    string :name, description: "Product name"
    number :price, description: "Price in USD"
    string :category, required: false
  end

  class Address < Ask::Schema
    string :street
    string :city
    string :zip
  end

  class Order < Ask::Schema
    string :id
    array :items, of: :string
    object :shipping, of: Address
  end

  def test_class_based_schema_has_properties
    assert Product.properties.key?(:name)
    assert Product.properties.key?(:price)
    assert Product.properties.key?(:category)
  end

  def test_class_based_required_properties
    assert_includes Product.required_properties, :name
    assert_includes Product.required_properties, :price
    refute_includes Product.required_properties, :category
  end

  def test_class_based_to_json_schema
    output = Product.new("product", description: "A product").to_json_schema

    assert_equal "product", output[:name]
    assert_equal "A product", output[:description]
    assert output.dig(:schema, :properties).key?(:name)
  end

  def test_inheritance_does_not_share_state
    assert Product.properties.key?(:name)
    refute Address.properties.key?(:name)
  end

  def test_nested_class_schema
    output = Order.new("order").to_json_schema

    assert_equal "object", output.dig(:schema, :properties, :shipping, :type)
    assert output.dig(:schema, :properties, :shipping, :properties).key?(:street)
  end

  def test_instance_validates
    product = Product.new
    assert product.valid?
  end

  def test_class_validates
    assert Product.valid?
  end

  def test_instance_method_missing_delegates_to_class
    schema = Ask::Schema.create do
      string :name
    end

    instance = schema.new("test")

    # Instance delegates DSL methods to class via method_missing
    assert instance.respond_to?(:string)
    assert instance.respond_to?(:number)
    assert instance.respond_to?(:object)
    assert instance.respond_to?(:array)
    assert instance.respond_to?(:any_of)
    assert instance.respond_to?(:one_of)
    assert instance.respond_to?(:null)
  end
end
