require_relative "lib/ask/schema/version"

Gem::Specification.new do |spec|
  spec.name = "ask-schema"
  spec.version = Ask::Schema::VERSION
  spec.authors = ["Kaka Ruto"]
  spec.email = ["kaka@myrrlabs.com"]

  spec.summary = "JSON Schema DSL for Ruby"
  spec.description = "A compact Ruby DSL for building standards-oriented JSON Schema documents. Zero dependencies."
  spec.homepage = "https://github.com/ask-rb/ask-schema"
  spec.license = "MIT"

  spec.required_ruby_version = ">= 3.2"

  spec.files = Dir["lib/**/*", "LICENSE", "README.md"]
  spec.require_paths = ["lib"]

  spec.add_development_dependency "minitest", "~> 5.25"
  spec.add_development_dependency "mocha", "~> 3.1"
  spec.add_development_dependency "rake", "~> 13.0"
end
