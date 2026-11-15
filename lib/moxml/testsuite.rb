# frozen_string_literal: true

require "json"
require_relative "testsuite/dataset"
require_relative "testsuite/report"
require_relative "testsuite/reference"
require_relative "testsuite/families/serialization"
require_relative "testsuite/families/c14n"
require_relative "testsuite/families/xsd_structural"
require_relative "testsuite/families/entity_registry"
require_relative "testsuite/families/decisions"

module Moxml
  module TestSuite
    # The certification runner. Give it a facade implementing the
    # certification protocol and it drives every engine-implementable
    # family in the dataset, returning a Report.
    #
    # The protocol (all methods required unless noted):
    #
    #   parse(xml_string)                  -> a document handle
    #   serialize(doc)                     -> xml string (the model's
    #                                         emitter shapes)
    #   canonicalize(doc)                  -> C14N 1.0 bytes
    #   validate_xsd(schema_xml, instance) -> [] | [#to_s messages]
    #   lexical_valid?(type_name, lexical) -> bool
    #   wildcard_covers?(...)              -> bool
    #   wildcard_exclusion?(...)           -> String | nil
    #   entity_declared? / entity_codepoint / entity_names /
    #     entity_primary_name / entity_standard? /
    #     entity_should_restore?           -> the registry answers
    #   regex_translates?(pattern)         -> regexp | nil
    #
    # The decision faces are the model's committed answers as pure
    # functions - the DOM faces wrap the same answers in a tree.
    # Reference (below) implements the whole protocol on moxml;
    # engines that cannot answer a family's faces see that family
    # SKIP, loudly - never a quiet pass.
    def self.run(facade, families: nil)
      dataset = Dataset.load
      families ||= Dataset::FAMILIES
      report = Report.new(facade_class: facade.class.name)
      families.each do |family|
        runner = runner_for(family, facade, dataset)
        next report.skip(family, "not certifiable by this facade") unless runner

        runner.call(report)
      end
      report
    end

    def self.runner_for(family, facade, dataset)
      case family
      when "serialization" then Families::Serialization.new(facade, dataset)
      when "c14n" then Families::C14n.new(facade, dataset)
      when "xsd_structural" then Families::XsdStructural.new(facade, dataset)
      when "entity_registry" then Families::EntityRegistry.new(facade, dataset)
      when "builtin_lexical", "schema_wildcards", "xsd_regex_translation"
        Families::Decisions.new(facade, dataset)
      end
    end
  end
end
