# ask-schema — JSON Schema DSL

## Purpose

A compact Ruby DSL for building JSON Schema documents. Zero dependencies.

Used by tools (for parameter definitions) and structured output (for response formats).
Extracted from `ruby_llm-schema` — this is the replacement for when we drop `ruby_llm`.

**IMPORTANT:** This gem is Phase 3 of the migration plan. Do NOT build until `ask-core`
and `ask-llm-providers` are built and stable. The ecosystem currently depends on
`ruby_llm-schema` which works fine until we decouple.

## Dependencies

- **Runtime:** none (stdlib only)
- **Build/test:** minitest, mocha, rake
- **No other ask-rb gems required.**

## Implementation Steps

### 1. Study ruby_llm-schema
- Source: `/Users/kaka/Code/ask-rb/ruby_llm-schema/lib/`
- This is the reference implementation. The schema DSL is already standalone with zero deps.
- The ask-rb version is a namespace repackage (ruby_llm-schema → ask-schema) with possible API refinements.

### Full ruby_llm-schema breakdown (must port all of this):

| Module | Lines | What it does |
|---|---|---|
| schema.rb | 99 | Main class. DSL inheritance, properties, required_properties, definitions, validate!, valid?, strict |
| dsl.rb | 19 | Assembles all DSL modules |
| dsl/schema_builders.rb | 196 | **Core.** string_schema, number_schema, integer_schema, boolean_schema, null_schema, object_schema, array_schema, any_of_schema, one_of_schema |
| dsl/primitive_types.rb | 29 | string(name), number(name), integer(name), boolean(name), null(name) — DSL wrappers |
| dsl/complex_types.rb | 32 | object(name), array(name), any_of(name), one_of(name), enum(name), const(name) |
| dsl/conditionals.rb | 169 | Complex: if_then, if_then_else, dependent/required, dependent/schemas, conditions builder |
| dsl/utilities.rb | 63 | define (named sub-schemas), reference ($ref), merge_conditions, helpers |
| json_output.rb | 36 | to_json_schema — final output with $defs, strict, additionalProperties |
| validator.rb | 93 | Circular reference detection via DFS topology sort |
| errors.rb | 30 | Error types |
| helpers.rb | 10 | Stub |

**Total: ~700 lines across 12 files. Zero dependencies.**
Port every one. No shortcuts — each module serves a specific purpose and skipping any
will produce a subpar schema gem that cannot replace ruby_llm-schema.

### 2. Define gem scaffold
- `lib/ask-schema.rb` — entry point
- `lib/ask/schema.rb` — main module
- `lib/ask/schema/version.rb`
- `ask-schema.gemspec` — zero runtime dependencies

### 3. Implement DSL builder (`lib/ask/schema.rb`)
- `Ask::Schema.define { ... }` — block-based DSL
- Type helpers: `string`, `number`, `integer`, `boolean`, `array`, `object`, `enum`
- Composition: `any_of`, `all_of`, `one_of`
- Modifiers: `description`, `default`, `minimum`, `maximum`, `pattern`, etc.
- `to_h` — returns JSON Schema hash

### 4. Implement class-based schema (`lib/ask/schema/base.rb`, if needed)
- `class ProductSchema < Ask::Schema; string :name; number :price; end`
- `ProductSchema.new.to_h`

### 5. Integration with ask-tools
- `Ask::Tool` uses `Ask::Schema` for generating parameter schemas from the `param` DSL
- This replaces the inline `SchemaDefinition` class in `RubyLLM::Tool`

### 6. Test coverage
- Test each type helper produces correct JSON Schema
- Test composition (`any_of`, `all_of`, `one_of`)
- Test modifiers (description, default, min/max, pattern)
- Test block-based and class-based APIs
- Test `to_h` output matches JSON Schema Draft 07/2020-12
- Test empty schemas
- Test nested schemas

### 7. README
- Quick start with `Ask::Schema.define`
- Each type documented
- Composition patterns
- Integration with tools

## Documentation

- **Update ask-docs** after releasing v0.1.0 — the docs site at github.com/ask-rb/ask-docs
  must reflect this gem's API, usage, and position in the ecosystem.

## Reference Repositories (Local)

All ask-rb gem repos are available locally at /Users/kaka/Code/ask-rb/ for reference.
Do not clone from GitHub — use the local directories:
- Source code: `/Users/kaka/Code/ask-rb/ask-schema/lib/`
- Tests: `/Users/kaka/Code/ask-rb/ask-schema/test/`
- Goal: `/Users/kaka/Code/ask-rb/ask-schema/GOAL.md`

Key reference:
- `/Users/kaka/Code/ask-rb/ruby_llm-schema/` — the existing implementation to study

## Release Checklist (Required for v0.1.0)

- [ ] All tests pass with >90% coverage
- [ ] Every public API method has documentation
- [ ] README is complete
- [ ] CHANGELOG.md exists with v0.1.0 entry
- [ ] All code committed and pushed to github.com/ask-rb/ask-schema
- [ ] Gem builds without errors: `gem build ask-schema.gemspec`
- [ ] Gem released as a private gem
- [ ] A consumer can install, require, and use `Ask::Schema.define` with no errors

## Development Workflow

### Git conventions
- The default branch is **master**. All work should be based on master unless a specific branch is requested.

- Follow the git-workflow skill.
- Conventional commits: `feat:`, `fix:`, `docs:`, `test:`, `refactor:`, `chore:`.
- One logical change per commit.

### Testing
- Minitest (not RSpec). No VCR needed — pure logic, no external calls.
- Unit tests for every public method.
- Run full suite before every commit: `bundle exec rake test`.
