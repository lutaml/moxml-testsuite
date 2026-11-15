# frozen_string_literal: true

module Moxml
  module TestSuite
    module Families
      # Family: c14n (14 rows). Canonical XML 1.0, byte-identical:
      # sorted attributes, expanded references, comments dropped.
      # Facade: parse(xml) -> doc; canonicalize(doc) -> string.
      class C14n
        def initialize(facade, dataset)
          @facade = facade
          @rows = dataset.rows("c14n")
        end

        def call(report)
          unless @facade.respond_to?(:canonicalize)
            return report.skip("c14n", "facade does not implement canonicalize")
          end

          failures = []
          @rows.each do |row|
            doc = @facade.parse(row["input"])
            out = @facade.canonicalize(doc)
            if out != row["canonical"]
              failures << format("%s: got %s, want %s",
                                 row["id"], out.inspect,
                                 row["canonical"].inspect)
            end
          rescue StandardError => e
            failures << format("%s: raised %s: %s", row["id"], e.class,
                               e.message[0, 120])
          end
          if failures.empty?
            report.pass("c14n", @rows.length)
          else
            report.fail("c14n", failures, @rows.length)
          end
        end
      end
    end
  end
end
