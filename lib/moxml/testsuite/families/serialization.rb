# frozen_string_literal: true

module Moxml
  module TestSuite
    module Families
      # Family: serialization (20 rows). The emitter contract:
      # long-form empty elements, the attribute escaping shapes
      # (named + numeric references), namespace declarations
      # verbatim. Facade: parse(xml) -> doc; serialize(doc) -> string.
      class Serialization
        def initialize(facade, dataset)
          @facade = facade
          @rows = dataset.rows("serialization")
        end

        def call(report)
          failures = []
          @rows.each do |row|
            doc = @facade.parse(row["input"])
            out = @facade.serialize(doc)
            # A single trailing document newline is formatting, not a
            # committed emitter shape - the dataset rows are chomped.
            if out&.chomp != row["output"]
              failures << format("%s: got %s, want %s",
                                 row["id"], out.inspect, row["output"].inspect)
            end
          rescue StandardError => e
            failures << format("%s: raised %s: %s", row["id"], e.class,
                               e.message[0, 120])
          end
          if failures.empty?
            report.pass("serialization", @rows.length)
          else
            report.fail("serialization", failures, @rows.length)
          end
        end
      end
    end
  end
end
