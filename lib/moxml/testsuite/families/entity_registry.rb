# frozen_string_literal: true

module Moxml
  module TestSuite
    module Families
      # Family: entity_registry (11 rows). The registry contract:
      # lookup (declared?, codepoint_for_name, names_for_codepoint,
      # primary_name_for_codepoint, standard_entity?) and restoration
      # (should_restore? under a restoration mode). Facade faces are
      # seed-scoped - every call carries the seed map so engines stay
      # stateless across rows:
      #
      #   entity_declared?(seed:, name:)
      #   entity_codepoint(seed:, name:)
      #   entity_names(seed:, codepoint:)
      #   entity_primary_name(seed:, codepoint:)
      #   entity_standard?(seed:, codepoint:)
      #   entity_should_restore?(seed:, codepoint:, restore_entities:,
      #                          restoration_mode:)
      class EntityRegistry
        def initialize(facade, dataset)
          @facade = facade
          @rows = dataset.rows("entity_registry")
        end

        def call(report)
          unless @facade.respond_to?(:entity_declared?)
            return report.skip("entity_registry",
                               "facade does not implement the registry faces")
          end

          failures = []
          @rows.each do |row|
            failures.concat(check_row(row))
          end
          if failures.empty?
            report.pass("entity_registry", @rows.length)
          else
            report.fail("entity_registry", failures,
                        @rows.length)
          end
        end

        private

        def check_row(row)
          seed = row["seed"]
          label = "#{row['qname'].inspect}/#{row['qcp']} seed=#{seed.inspect}"
          [
            [row["declared"],
             @facade.entity_declared?(seed: seed, name: row["qname"])],
            [row["codepoint"],
             @facade.entity_codepoint(seed: seed, name: row["qname"])],
            [row["names"],
             @facade.entity_names(seed: seed, codepoint: row["qcp"])],
            [row["primary"],
             @facade.entity_primary_name(seed: seed, codepoint: row["qcp"])],
            [row["standard"],
             @facade.entity_standard?(seed: seed, codepoint: row["qcp"])],
            [row["restore"],
             @facade.entity_should_restore?(
               seed: seed, codepoint: row["qcp"],
               restore_entities: row["restore_entities"],
               restoration_mode: row["mode"]
             )],
          ].filter_map do |want, got|
            next if want == got

            format("%s: got %s, want %s", label, got.inspect, want.inspect)
          end
        rescue StandardError => e
          [format("%s: raised %s: %s", label, e.class, e.message[0, 120])]
        end
      end
    end
  end
end
