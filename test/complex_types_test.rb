# frozen_string_literal: true

require_relative "test_helper"

class ComplexTypesTest < Minitest::Test
  def test_object_property_with_block
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

  def test_object_property_with_reference
    Ask::Schema.create do
      define(:address) do
        string :street
        string :city
      end
    end

    schema = Ask::Schema.create do
      define(:address) do
        string :street
      end
      object :home, of: :address
    end

    assert_equal "#/$defs/address", schema.properties[:home]["$ref"]
  end

  def test_array_property_with_primitive_of
    schema = Ask::Schema.create do
      array :tags, of: :string, description: "Tags"
    end

    prop = schema.properties[:tags]
    assert_equal "array", prop[:type]
    assert_equal "string", prop.dig(:items, :type)
  end

  def test_array_property_with_block
    schema = Ask::Schema.create do
      array :contacts do
        object do
          string :name
          string :email
        end
      end
    end

    prop = schema.properties[:contacts]
    assert_equal "array", prop[:type]
    assert_equal "object", prop.dig(:items, :type)
  end

  def test_array_with_min_max_items
    schema = Ask::Schema.create do
      array :tags, of: :string, min_items: 1, max_items: 10
    end

    assert_equal 1, schema.properties[:tags][:minItems]
    assert_equal 10, schema.properties[:tags][:maxItems]
  end

  def test_any_of_property
    schema = Ask::Schema.create do
      any_of :contact do
        string description: "Phone"
        object do
          string :email
        end
      end
    end

    prop = schema.properties[:contact]
    assert prop.key?(:anyOf)
    assert_equal 2, prop[:anyOf].length
  end

  def test_one_of_property
    schema = Ask::Schema.create do
      one_of :payment do
        string :credit_card
        string :paypal
      end
    end

    prop = schema.properties[:payment]
    assert prop.key?(:oneOf)
    assert_equal 2, prop[:oneOf].length
  end

  def test_optional_property
    schema = Ask::Schema.create do
      string :name
      optional :nickname do
        string
      end
    end

    prop = schema.properties[:nickname]
    assert prop.key?(:anyOf)
    assert_includes prop[:anyOf], type: "null"
  end
end
