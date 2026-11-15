# frozen_string_literal: true

require "spec_helper"

RSpec.describe Moxml::TestSuite do
  let(:report) { described_class.run(Moxml::TestSuite::Reference.new) }

  it "certifies the reference facade on every family" do
    expect(report.passed?).to be(true), report.summary
  end

  it "drives all seven families - decisions reports as one group" do
    expect(Moxml::TestSuite::Dataset::FAMILIES).to contain_exactly(
      "builtin_lexical", "xsd_regex_translation", "schema_wildcards",
      "entity_registry", "serialization", "c14n", "xsd_structural"
    )
    expect(report.results.keys).to contain_exactly(
      "decisions", "entity_registry", "serialization", "c14n",
      "xsd_structural"
    )
  end

  it "drives every row in the vendored dataset" do
    dataset = Moxml::TestSuite::Dataset.load
    total = Moxml::TestSuite::Dataset::FAMILIES.sum { |f| dataset.rows(f).length }
    answered = report.results.values.sum { |r| r[:count] || 0 }
    expect(answered).to eq(total)
  end

  it "skips families the facade cannot answer, loudly" do
    partial = Class.new do
      def initialize
        @ctx = Moxml.new(:nokogiri)
        @ctx.config.default_indent = 0
      end

      def parse(xml)
        @ctx.parse(xml)
      end

      def serialize(doc)
        doc.to_xml
      end
    end
    report = described_class.run(partial.new)
    expect(report.results["serialization"][:status]).to eq(:pass)
    expect(report.results["c14n"][:status]).to eq(:skip)
    expect(report.results["xsd_structural"][:status]).to eq(:skip)
    expect(report.results["decisions"][:status]).to eq(:skip)
    expect(report.results["entity_registry"][:status]).to eq(:skip)
    expect(report.passed?).to be(true)
  end

  it "fails loudly when a face answers against the dataset" do
    wrong = Class.new(Moxml::TestSuite::Reference) do
      def lexical_valid?(_type_name, _lexical)
        false
      end
    end
    report = described_class.run(wrong.new)
    expect(report.passed?).to be(false)
    expect(report.failures.keys).to include("decisions")
  end

  it "names the facade in the summary" do
    expect(report.summary).to include("Reference")
  end
end
