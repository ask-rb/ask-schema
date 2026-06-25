## [0.1.1] - 2026-06-25

### Changed
- Robustness suite (11 tests): empty schemas, edge cases, schema isolation. Infrastructure: rubocop, overcommit, bin/setup, CI matrix, gemspec test.
# Changelog

## [0.1.0] - 2026-06-21

### Added

- Initial release of `ask-schema` — a zero-dependency Ruby DSL for building JSON Schema documents.
- Ported from `ruby_llm-schema` v0.4.0 with namespace repackage (`RubyLLM::Schema` → `Ask::Schema`).

### Features

- **Block-based DSL** — `Ask::Schema.create { string(:name); integer(:age) }` for inline schema definitions
- **Class-based DSL** — `class Product < Ask::Schema; string :name; end` for reusable schema classes
- **Primitive types** — `string`, `number`, `integer`, `boolean`, `null` with full constraint support
- **Complex types** — `object`, `array`, `any_of`, `one_of`, `enum`, `const`
- **Composition** — `define`/`reference` for named sub-schemas with `$defs` and `$ref`
- **Conditionals** — `given`/`then`/`else` for conditional validation, `dependent` for property dependencies
- **Validation** — Circular reference detection via DFS topological sort
- **JSON output** — `to_json_schema` (hash) and `to_json` (pretty-printed JSON string)
- **Strict mode** — `strict`, `additionalProperties` controls with sensible defaults
- **Modifiers** — `description`, `default`, `minimum`, `maximum`, `pattern`, `format`, `min_length`, `max_length`, `enum`, `multiple_of`, `min_items`, `max_items`
- **Optional fields** — `required: false` and `optional { ... }` helper for nullable properties
- **Dependencies** — Zero runtime dependencies. stdlib only (`json`).
- **Ruby 3.2+** — Uses anonymous block forwarding, endless methods, and modern Ruby idioms.

### Ported modules

| Module | Source | Lines |
|---|---|---|
| `Ask::Schema` | `lib/ask/schema.rb` | 99 |
| DSL assembly | `lib/ask/schema/dsl.rb` | 19 |
| Schema builders | `lib/ask/schema/dsl/schema_builders.rb` | 186 |
| Primitive types | `lib/ask/schema/dsl/primitive_types.rb` | 29 |
| Complex types | `lib/ask/schema/dsl/complex_types.rb` | 32 |
| Conditionals | `lib/ask/schema/dsl/conditionals.rb` | 169 |
| Utilities | `lib/ask/schema/dsl/utilities.rb` | 62 |
| JSON output | `lib/ask/schema/json_output.rb` | 37 |
| Validator | `lib/ask/schema/validator.rb` | 81 |
| Errors | `lib/ask/schema/errors.rb` | 30 |
| Helpers | `lib/ask/schema/helpers.rb` | 12 |
