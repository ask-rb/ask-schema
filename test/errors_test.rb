# frozen_string_literal: true

require_relative "test_helper"

class ErrorsTest < Minitest::Test
  def test_error_base_class
    assert Ask::Schema::Error < StandardError
  end

  def test_invalid_schema_type_error_message
    error = Ask::Schema::InvalidSchemaTypeError.new(:foobar)
    assert_equal "Unknown schema type: foobar", error.message
  end

  def test_invalid_array_type_error
    assert Ask::Schema::InvalidArrayTypeError < Ask::Schema::Error
  end

  def test_invalid_object_type_error
    assert Ask::Schema::InvalidObjectTypeError < Ask::Schema::Error
  end

  def test_invalid_schema_error
    assert Ask::Schema::InvalidSchemaError < Ask::Schema::Error
  end

  def test_validation_error
    assert Ask::Schema::ValidationError < Ask::Schema::Error
  end

  def test_limit_exceeded_error
    assert Ask::Schema::LimitExceededError < Ask::Schema::Error
  end

  def test_invalid_array_type_raises_for_nonsense_type
    assert_raises(Ask::Schema::InvalidArrayTypeError) do
      Ask::Schema.create do
        array :bad, of: 42
      end
    end
  end

  def test_invalid_object_type_raises_for_nonsense_type
    assert_raises(Ask::Schema::InvalidObjectTypeError) do
      Ask::Schema.create do
        object :bad, of: 42
      end
    end
  end
end
