# frozen_string_literal: true

module Moxml
  module TestSuite
    module Families
      # Family: xsd_structural (6 rows). Schema + instance pairs
      # with the committed verdict. Facade: parse(xml);
      # validate_xsd(schema_xml, instance) -> [] (valid) | [#to_s].
      class XsdStructural
        def initialize(facade, dataset)
          @facade = facade
          @rows = dataset.rows("xsd_structural")
        end

        def call(report)
          unless @facade.respond_to?(:validate_xsd)
            return report.skip("xsd_structural",
                               "facade does not implement validate_xsd")
          end

          failures = []
          @rows.each do |row|
            errs = @facade.validate_xsd(row["schema"], row["instance"])
            valid = errs.nil? || errs.empty?
            expected = row["valid"]
            if valid != expected
              failures << format("%s: expected %s, engine said %s (%s)",
                                 row["id"], expected, valid,
                                 Array(errs).first || "no rows")
            end
          rescue StandardError => e
            failures << format("%s: raised %s: %s", row["id"], e.class,
                               e.message[0, 120])
          end
          if failures.empty?
            report.pass("xsd_structural", @rows.length)
          else
            report.fail("xsd_structural", failures,
                        @rows.length)
          end
        end
      end
    end
  end
end
