# frozen_string_literal: true

require "json"

module Moxml
  module TestSuite
    # The vendored dataset: the model's committed answers, seven
    # families, schema-versioned. The JSON is the single source -
    # runners consume rows, never restate them.
    module Dataset
      FAMILIES = %w[
        builtin_lexical
        xsd_regex_translation
        schema_wildcards
        entity_registry
        serialization
        c14n
        xsd_structural
      ].freeze

      DATA_PATH = File.join(__dir__, "../../../testdata/moxml-conformance.json")

      def self.load(path: DATA_PATH)
        raw = JSON.parse(File.read(path))
        Dataset::V1.new(raw)
      end

      class V1
        attr_reader :schema, :generator, :cases

        def initialize(raw)
          @schema = raw["schema"]
          @generator = raw["generator"]
          @cases = raw["cases"]
        end

        def rows(family)
          @cases.fetch(family)
        end
      end
    end
  end
end
