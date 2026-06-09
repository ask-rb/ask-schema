# ask-schema

A compact Ruby DSL for building standards-compliant JSON Schema documents. Zero dependencies.

```ruby
gem "ask-schema"
```

```ruby
require "ask-schema"

schema = Ask::Schema.create do
  string :name, description: "Full name"
  integer :age, description: "Age in years", minimum: 0
  boolean :active, required: false
end

schema.new("user", description: "A user profile").to_json
# => {
#   "name": "user",
#   "description": "A user profile",
#   "schema": {
#     "type": "object",
#     "properties": {
#       "name": { "type": "string", "description": "Full name" },
#       "age": { "type": "integer", "description": "Age in years", "minimum": 0 },
#       "active": { "type": "boolean" }
#     },
#     "required": ["name", "age"],
#     "additionalProperties": false,
#     "strict": true
#   }
# }
```

## Quick Start

### Block-based DSL

```ruby
schema = Ask::Schema.create do
  string :name, description: "The user's name"
  integer :age, description: "Age in years"
  boolean :active, required: false
end

instance = schema.new("user_profile", description: "A user profile")
instance.to_json_schema
# => { name: "user_profile", description: "A user profile", schema: { ... } }
```

### Class-based DSL

```ruby
class Address < Ask::Schema
  string :street
  string :city
  string :zip
  string :country, required: false
end

class User < Ask::Schema
  string :name, description: "Full name"
  string :email, format: "email"
  integer :age
  object :address, of: Address
end

User.new("user").to_json_schema
```

## Primitive Types

Each primitive type supports standard JSON Schema constraints.

### String

```ruby
string :username,
  description: "Username",
  enum: %w[admin user guest],
  min_length: 3,
  max_length: 50,
  pattern: "^[a-zA-Z0-9_]+$",
  format: "email"
```

### Number

```ruby
number :price,
  description: "Price in USD",
  minimum: 0,
  maximum: 999999.99,
  multiple_of: 0.01
```

### Integer

```ruby
integer :age,
  minimum: 0,
  maximum: 150
```

### Boolean

```ruby
boolean :active, description: "Is the user active?"
```

### Null

```ruby
null :deleted_at, description: "When the record was deleted"
```

## Complex Types

### Object

```ruby
# Inline object
object :address do
  string :street
  string :city
  string :zip
end

# Reference to a defined schema
define(:address) do
  string :street
  string :city
end
object :billing, of: :address

# Reference to a Schema class
object :shipping, of: Address
```

### Array

```ruby
# Array of primitive type
array :tags, of: :string, description: "List of tags"

# Array with min/max items
array :prices, of: :number, min_items: 1, max_items: 100

# Array with complex items (block)
array :contacts do
  object do
    string :name
    string :email
  end
end

# Array with any_of items
array :identifiers do
  any_of do
    string
    integer
  end
end
```

### any_of / one_of

```ruby
any_of :contact do
  string description: "Phone number"
  object do
    string :email
  end
end

one_of :payment_method do
  string :credit_card
  string :paypal
end
```

### Optional (nullable)

```ruby
optional :nickname do
  string
end
# Produces: anyOf: [{ type: "string" }, { type: "null" }]
```

## Named Definitions and References

Use `define` to create reusable named sub-schemas and `reference` (or `of:`) to reference them:

```ruby
class User < Ask::Schema
  define(:address) do
    string :street
    string :city
    string :zip
  end

  string :name
  object :home_address, of: :address
  object :work_address, of: :address
end
```

Output includes proper `$defs` and `$ref`:

```json
{
  "type": "object",
  "properties": {
    "name": { "type": "string" },
    "home_address": { "$ref": "#/$defs/address" },
    "work_address": { "$ref": "#/$defs/address" }
  },
  "$defs": {
    "address": {
      "type": "object",
      "properties": { "street": { "type": "string" }, ... }
    }
  }
}
```

## Conditionals

### If/Then/Else

```ruby
schema = Ask::Schema.create do
  integer :age
  string :country

  given(age: 18, country: "US") do
    requires :license_number
    validates :license_number, type: :string, pattern: /^[A-Z]{2}\d{6}$/
    otherwise do
      requires :country_name
    end
  end
end
```

### Dependent Required

```ruby
dependent :shipping_address do
  requires :name, :street, :city
end
```

### Coercion rules

| Ruby value | JSON Schema |
|---|---|
| `18` (scalar) | `{ const: 18 }` |
| `["admin", "user"]` (Array) | `{ enum: ["admin", "user"] }` |
| `/^[A-Z]+$/` (Regexp) | `{ pattern: "^[A-Z]+$" }` |
| `{ minimum: 0 }` (Hash) | Passed through as-is |

## Validation

```ruby
schema = Ask::Schema.create { string :name }
schema.valid? # => true
schema.validate! # => nil (or raises Ask::Schema::ValidationError)

# Circular reference detection
schema = Ask::Schema.create do
  define(:a) { object :b, of: :b }
  define(:b) { object :a, of: :a }
end
schema.valid? # => false
schema.validate! # => raises Ask::Schema::ValidationError
```

## Output Formats

```ruby
instance.to_json_schema
# => Hash with :name, :description, :schema keys

instance.to_json
# => Pretty-printed JSON string
```

## Configuration

```ruby
class StrictSchema < Ask::Schema
  string :name
  strict true              # defaults to true
  additional_properties false  # defaults to false
end
```

## Integration with ask-tools

`ask-schema` powers tool parameter schemas in `ask-tools`:

```ruby
class WeatherTool < Ask::Tool
  description "Get weather for a location"

  params do
    string :location, description: "City name"
    string :unit, enum: %w[celsius fahrenheit]
  end

  def execute(location:, unit: "celsius")
    # ...
  end
end
```

Under the hood, `Ask::Schema.create` is used to build the JSON Schema for tool parameters.

## Error Types

| Error | When |
|---|---|
| `Ask::Schema::InvalidArrayTypeError` | Invalid type for array `:of` |
| `Ask::Schema::InvalidObjectTypeError` | Invalid type for object `:of` |
| `Ask::Schema::ValidationError` | Schema validation fails (e.g., circular refs) |
| `Ask::Schema::InvalidSchemaTypeError` | Unknown schema type specified |
| `Ask::Schema::InvalidSchemaError` | Schema definition is invalid |
| `Ask::Schema::LimitExceededError` | Maximum limits exceeded |

## Development

```
bundle install
bundle exec rake test
```

## Status

**Phase 3** of the ask-rb ecosystem migration. This gem replaces `ruby_llm-schema`
in the ask-rb stack. It should be built after `ask-core` and `ask-llm-providers`
are stable.

Current state: v0.1.0 — initial port complete with full feature parity.

## License

MIT
