# ask-schema

A compact Ruby DSL for building standards-oriented JSON Schema documents.
Zero dependencies. Extracted from `ruby_llm-schema` — this is the replacement
for when we drop `ruby_llm` as a dependency.

## Installation

```ruby
gem "ask-schema"
```

## Usage

```ruby
schema = Ask::Schema.define do
  string :name, description: "The name"
  number :price, description: "The price"
  any_of :contact do
    string :email
    string :phone
  end
  array :tags, of: :string
  enum :status, values: %w[active inactive]
end

schema.to_h
# => { type: "object", properties: { name: { type: "string" }, ... } }
```

## Development

```bash
bundle exec rake test
```

## License

MIT
