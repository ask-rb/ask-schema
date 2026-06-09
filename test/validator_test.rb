# frozen_string_literal: true

require_relative "test_helper"

class ValidatorTest < Minitest::Test
  def test_simple_schema_is_valid
    schema = Ask::Schema.create do
      string :name
      integer :age
    end

    assert schema.valid?
  end

  def test_validate_does_not_raise_on_valid_schema
    schema = Ask::Schema.create do
      string :name
    end

    assert_nil schema.validate!
  end

  def test_empty_schema_is_valid
    schema = Ask::Schema.create do
    end

    assert schema.valid?
  end

  def test_detects_circular_reference
    schema = Ask::Schema.create do
      define(:a) do
        object :ref, of: :b
      end
      define(:b) do
        object :ref, of: :a
      end
    end

    refute schema.valid?
    assert_raises(Ask::Schema::ValidationError) { schema.validate! }
  end

  def test_self_reference_is_circular
    schema = Ask::Schema.create do
      define(:self_ref) do
        object :nested, of: :self_ref
      end
    end

    refute schema.valid?
  end

  def test_no_false_positive_on_non_circular_refs
    schema = Ask::Schema.create do
      define(:a) do
        string :name
      end
      define(:b) do
        object :item, of: :a
      end
    end

    assert schema.valid?
  end

  def test_validation_error_message
    schema = Ask::Schema.create do
      define(:x) do
        object :loop, of: :y
      end
      define(:y) do
        object :loop, of: :x
      end
    end

    error = assert_raises(Ask::Schema::ValidationError) { schema.validate! }
    assert_match(/Circular reference/, error.message)
  end
end
