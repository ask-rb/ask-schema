# frozen_string_literal: true

require_relative "test_helper"

class PrimitiveTypesTest < Minitest::Test
  def test_string_property
    schema = Ask::Schema.create do
      string :name
    end

    prop = schema.properties[:name]
    assert_equal "string", prop[:type]
  end

  def test_string_with_options
    schema = Ask::Schema.create do
      string :code, description: "The code", enum: %w[a b c], min_length: 2, max_length: 10, pattern: "^[A-Z]+$"
    end

    prop = schema.properties[:code]
    assert_equal "string", prop[:type]
    assert_equal %w[a b c], prop[:enum]
    assert_equal 2, prop[:minLength]
    assert_equal 10, prop[:maxLength]
    assert_equal "^[A-Z]+$", prop[:pattern]
  end

  def test_string_format
    schema = Ask::Schema.create do
      string :email, format: "email"
    end

    assert_equal "email", schema.properties[:email][:format]
  end

  def test_number_property
    schema = Ask::Schema.create do
      number :price
    end

    assert_equal "number", schema.properties[:price][:type]
  end

  def test_number_with_constraints
    schema = Ask::Schema.create do
      number :price, minimum: 0, maximum: 1000, multiple_of: 0.01
    end

    prop = schema.properties[:price]
    assert_equal 0, prop[:minimum]
    assert_equal 1000, prop[:maximum]
    assert_equal 0.01, prop[:multipleOf]
  end

  def test_integer_property
    schema = Ask::Schema.create do
      integer :count
    end

    assert_equal "integer", schema.properties[:count][:type]
  end

  def test_integer_with_constraints
    schema = Ask::Schema.create do
      integer :age, minimum: 0, maximum: 150
    end

    prop = schema.properties[:age]
    assert_equal 0, prop[:minimum]
    assert_equal 150, prop[:maximum]
  end

  def test_boolean_property
    schema = Ask::Schema.create do
      boolean :active
    end

    assert_equal "boolean", schema.properties[:active][:type]
  end

  def test_boolean_with_description
    schema = Ask::Schema.create do
      boolean :active, description: "Is the user active?"
    end

    assert_equal "Is the user active?", schema.properties[:active][:description]
  end

  def test_null_property
    schema = Ask::Schema.create do
      null :deleted_at
    end

    assert_equal "null", schema.properties[:deleted_at][:type]
  end
end
