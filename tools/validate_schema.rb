#!/usr/bin/env ruby
# frozen_string_literal: true

# Independent structural validation of the conformance dataset.
# Gem-free: the moxml implementation is NOT loaded, so this cannot
# inherit the exporter's logic (plain `ruby`, no bundle).
#
#   1. Every row validates against schema/test.schema.json via the
#      fail-closed subset engine.
#   2. Dataset invariants: schema + generator present; every declared
#      family non-empty; ids unique within their family.
#   3. Language independence: no implementation class names or engine
#      identifiers anywhere in the data.
#
# An empty dataset fails - an empty file can never look like a pass.
#
# Usage: ruby tools/validate_schema.rb
# Exits nonzero on any violation.

require "json"
require_relative "json_schema_subset"

REPO = File.expand_path("..", __dir__)
DATA = File.join(REPO, "tests", "moxml-conformance.json")
SCHEMA = File.join(REPO, "schema", "test.schema.json")

FAMILIES = %w[
  builtin_lexical xsd_regex_translation schema_wildcards
  entity_registry serialization c14n xsd_structural
].freeze

ID_FAMILIES = %w[serialization c14n xsd_structural].freeze

failures = 0

raw = File.read(DATA)
begin
  dataset = JSON.parse(raw)
rescue JSON::ParserError => e
  puts "FATAL: the dataset is not valid JSON: #{e.message[0, 120]}"
  exit 1
end

version = dataset.is_a?(Hash) && dataset["schema"]
unless version.is_a?(Integer) && version >= 1
  puts "FAIL: dataset schema version missing or invalid"
  failures += 1
end
unless dataset["generator"].is_a?(String) && !dataset["generator"].empty?
  puts "FAIL: dataset generator missing"
  failures += 1
end
cases = dataset["cases"]
unless cases.is_a?(Hash)
  puts "FATAL: dataset cases missing"
  exit 1
end

schema = JSON.parse(File.read(SCHEMA))

total = 0
FAMILIES.each do |family|
  rows = cases[family]
  unless rows.is_a?(Array) && !rows.empty?
    puts "FAIL: family #{family} missing or empty"
    failures += 1
    next
  end
  total += rows.length

  if ID_FAMILIES.include?(family)
    ids = rows.map { |r| r["id"] }
    dupes = ids.tally.select { |_, n| n > 1 }
    unless dupes.empty?
      puts "FAIL: family #{family} duplicate ids: #{dupes.keys.inspect}"
      failures += 1
    end
  end

  rows.each_with_index do |row, i|
    errors = JsonSchemaSubset.validate(schema, row)
    next if errors.empty?

    errors.each { |e| puts "FAIL: #{family}[#{i}] #{e}" }
    failures += 1
  end
end

extra = cases.keys - FAMILIES
unless extra.empty?
  puts "FAIL: undeclared families present: #{extra.inspect}"
  failures += 1
end

blob = JSON.generate(cases)
if blob.match?(/Moxml::|Leptris|nokogiri|Nokogiri/i)
  puts "FAIL: implementation class names or engine identifiers in the data"
  failures += 1
end

if total.zero?
  puts "FATAL: an empty dataset can never look like a pass"
  exit 1
end

if failures.zero?
  puts "SCHEMA VALIDATION PASS (#{total} rows, #{FAMILIES.length} families)"
else
  puts "SCHEMA VALIDATION FAIL (#{failures} violations)"
  exit 1
end
