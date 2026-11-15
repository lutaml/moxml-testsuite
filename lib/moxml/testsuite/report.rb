# frozen_string_literal: true

module Moxml
  module TestSuite
    # The certification outcome: per-family pass/fail/skip with the
    # failing case ids. Truthy: report.passed? after run.
    class Report
      attr_reader :facade_class, :results

      def initialize(facade_class:)
        @facade_class = facade_class
        @results = {}
      end

      def pass(family, count)
        @results[family] = { status: :pass, count: count, failures: [] }
      end

      def fail(family, failures, count)
        @results[family] = { status: :fail, count: count, failures: failures }
      end

      def skip(family, reason)
        @results[family] = { status: :skip, reason: reason }
      end

      def passed?
        @results.values.all? { |r| r[:status] != :fail }
      end

      def failures
        @results.select { |_, r| r[:status] == :fail }
      end

      def summary
        lines = ["moxml-testsuite (facade: #{@facade_class})"]
        @results.each do |family, r|
          case r[:status]
          when :pass then lines << "  PASS #{family} (#{r[:count]} cases)"
          when :fail
            lines << "  FAIL #{family} " \
                     "(#{r[:failures].length}/#{r[:count]} cases):"
            r[:failures].each { |f| lines << "       #{f}" }
          when :skip then lines << "  SKIP #{family} (#{r[:reason]})"
          end
        end
        lines.join("\n")
      end

      def to_s
        summary
      end
    end
  end
end
