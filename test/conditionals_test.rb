# frozen_string_literal: true

require_relative "test_helper"

class ConditionalsTest < Minitest::Test
  def test_given_creates_conditional
    schema = Ask::Schema.create do
      integer :age
      given(age: 18) do
        requires :license_number
      end
    end

    schema_class = schema
    refute_empty schema_class.conditions

    condition = schema_class.conditions.first
    assert condition.key?(:if)
    assert condition.key?(:then)
  end

  def test_given_with_enum_condition
    schema = Ask::Schema.create do
      string :country
      given(country: %w[US CA]) do
        requires :state
      end
    end

    condition = schema.conditions.first
    assert_equal :enum, condition.dig(:if, :properties, "country").keys.first
  end

  def test_given_with_regexp_condition
    schema = Ask::Schema.create do
      string :code
      given(code: /^[A-Z]+$/) do
        requires :validation
      end
    end

    condition = schema.conditions.first
    assert condition.dig(:if, :properties, "code", :pattern)
  end

  def test_given_with_then_else
    schema = Ask::Schema.create do
      string :country
      given(country: "US") do
        requires :state
        otherwise do
          requires :country_name
        end
      end
    end

    condition = schema.conditions.first
    assert condition.key?(:if)
    assert condition.key?(:then)
  end

  def test_dependent_creates_dependency
    schema = Ask::Schema.create do
      string :name
      string :shipping_address
      dependent :shipping_address do
        requires :name
      end
    end

    refute_empty schema.dependencies
  end

  def test_coerce_condition_with_array
    schema = Ask::Schema.create do
      string :role
      given(role: %w[admin moderator]) do
        requires :permissions
      end
    end

    condition = schema.conditions.first
    assert_equal({enum: %w[admin moderator]},
                 condition.dig(:if, :properties, "role"))
  end

  def test_coerce_condition_with_regexp
    schema = Ask::Schema.create do
      string :code
      given(code: /^ABC/) do
        requires :validation
      end
    end

    condition = schema.conditions.first
    assert_equal({pattern: "^ABC"},
                 condition.dig(:if, :properties, "code"))
  end

  def test_coerce_condition_with_scalar
    schema = Ask::Schema.create do
      integer :age
      given(age: 21) do
        requires :id
      end
    end

    condition = schema.conditions.first
    assert_equal({const: 21},
                 condition.dig(:if, :properties, "age"))
  end

  def test_given_raises_with_empty_properties
    assert_raises(ArgumentError) do
      Ask::Schema.create do
        given {}
      end
    end
  end

  def test_conditionals_in_json_schema
    schema = Ask::Schema.create do
      integer :age
      given(age: 18) do
        requires :license_number
      end
    end

    output = schema.new("test").to_json_schema
    condition = output.dig(:schema, :if)

    refute_nil condition
    assert condition.dig(:properties, "age").key?(:const)
  end
end
