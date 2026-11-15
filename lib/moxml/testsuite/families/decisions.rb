# frozen_string_literal: true

module Moxml
  module TestSuite
    module Families
      # Families: the pure-logic decision faces (the model's
      # committed answers as functions).
      #
      # builtin_lexical (81): lexical_valid?(type_name, lexical)
      # schema_wildcards (24): the pinned covers/exclusion protocol -
      #   wildcard_covers?(constraint:, process:, not_namespace:,
      #                    not_qname:, item_namespace:) -> bool
      #   wildcard_exclusion?(constraint:, process:, not_namespace:,
      #                       not_qname:, item_namespace:, item_name:,
      #                       defined:, sibling_names:) -> String | nil
      #   (the dataset's committed shape: a row answers covers? plus
      #   the negative-exclusion symbol; there is no single "admits")
      # xsd_regex_translation (21): regex_translates?(pattern) ->
      #   regexp | nil (nil = untranslatable per the model).
      class Decisions
        def initialize(facade, dataset)
          @facade = facade
          @dataset = dataset
        end

        DECISION_FACES = %i[
          lexical_valid? wildcard_covers? regex_translates?
        ].freeze

        def call(report)
          if DECISION_FACES.none? { |face| @facade.respond_to?(face) }
            return report.skip("decisions",
                               "facade does not implement the decision faces")
          end

          failures = []
          failures += run_lexical
          failures += run_wildcards
          failures += run_regex
          total = @dataset.rows("builtin_lexical").length +
            @dataset.rows("schema_wildcards").length +
            @dataset.rows("xsd_regex_translation").length
          if failures.empty?
            report.pass("decisions", total)
          else
            report.fail("decisions", failures, total)
          end
        end

        private

        def run_lexical
          return [] unless @facade.respond_to?(:lexical_valid?)

          @dataset.rows("builtin_lexical").filter_map do |row|
            next if @facade.lexical_valid?(row["type"],
                                           row["lexical"]) == row["valid"]

            format("lexical %s %s: got %s, want %s",
                   row["type"], row["lexical"].inspect,
                   !row["valid"], row["valid"])
          end
        rescue NoMethodError, ArgumentError => e
          ["lexical face unavailable: #{e.class}: #{e.message[0, 80]}"]
        end

        def run_wildcards
          return [] unless @facade.respond_to?(:wildcard_covers?)

          @dataset.rows("schema_wildcards").filter_map do |row|
            common = {
              constraint: row["constraint"], process: row["process"],
              not_namespace: row["not_namespace"],
              not_qname: Array(row["not_qname"]),
              item_namespace: row["item_namespace"]
            }
            covers = @facade.wildcard_covers?(**common)
            unless covers == row["covers"]
              next format("wildcard %s/%s covers?(%s): got %s, want %s",
                          row["constraint"], row["process"],
                          row["item_qname"], covers, row["covers"])
            end

            exclusion = @facade.wildcard_exclusion?(
              **common, item_name: row["item_qname"],
                        defined: row["defined"],
                        sibling_names: Array(row["sibling_names"])
            )
            want = row["exclusion"]
            next if exclusion.to_s == want.to_s

            format("wildcard %s/%s exclusion(%s): got %s, want %s",
                   row["constraint"], row["process"], row["item_qname"],
                   exclusion.inspect, want.inspect)
          end
        rescue NoMethodError, ArgumentError => e
          ["wildcard face unavailable: #{e.class}: #{e.message[0, 80]}"]
        end

        def run_regex
          return [] unless @facade.respond_to?(:regex_translates?)

          @dataset.rows("xsd_regex_translation").filter_map do |row|
            compiled = @facade.regex_translates?(row["pattern"])
            next if compiled.nil? != row["translatable"]

            next unless row["translatable"] &&
              compiled.match?(row["value"]) != row["matches"]

            format("regex %s %s: matched %s, want %s",
                   row["pattern"].inspect, row["value"].inspect,
                   compiled.match?(row["value"]), row["matches"])
          end
        rescue NoMethodError, ArgumentError => e
          ["regex face unavailable: #{e.class}: #{e.message[0, 80]}"]
        end
      end
    end
  end
end
