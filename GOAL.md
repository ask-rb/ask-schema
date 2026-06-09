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
- Follow the git-workflow skill.
- Conventional commits: `feat:`, `fix:`, `docs:`, `test:`, `refactor:`, `chore:`.
- One logical change per commit.

### Testing
- Minitest (not RSpec). No VCR needed — pure logic, no external calls.
- Unit tests for every public method.
- Run full suite before every commit: `bundle exec rake test`.
