# frozen_string_literal: true

require_relative "lib/moxml/testsuite/version"

Gem::Specification.new do |spec|
  spec.name = "moxml-testsuite"
  spec.version = Moxml::TestSuite::VERSION
  spec.authors = ["Ribose Inc."]
  spec.email = ["open.source@ribose.com"]

  spec.summary = "The moxml conformance test suite: certify any XML " \
                 "engine against the moxml model"
  spec.description = "The moxml model's committed answers as a certifiable " \
                     "test suite. Engines implement the certification " \
                     "facade (parse, serialize, canonicalize, XSD " \
                     "validation, and the pure-logic decision faces) and " \
                     "run the seven-family dataset - builtin lexical " \
                     "spaces, XSD pattern translation, namespace wildcards, " \
                     "the entity registry, serialization shapes, C14N " \
                     "vectors, and XSD structural validation. Any engine " \
                     "can certify against the model."
  spec.homepage = "https://github.com/lutaml/moxml-testsuite"
  spec.license = "MIT"

  spec.required_ruby_version = ">= 3.0"

  spec.files = Dir["lib/**/*.rb", "exe/*", "testdata/*.json", "README.adoc",
                   "LICENSE"]
  spec.bindir = "exe"
  spec.executables = ["moxml-testsuite"]
  spec.require_paths = ["lib"]

  spec.add_development_dependency "rake", "~> 13"
  spec.add_development_dependency "rspec", "~> 3.13"

  # The reference facade certifies through a real engine; nokogiri
  # is the dev default so the suite always has one to answer with.
  spec.add_development_dependency "moxml", "~> 0.6"
  spec.add_development_dependency "nokogiri", "~> 1.18"
  spec.metadata["rubygems_mfa_required"] = "true"
end
