#!/usr/bin/env ruby
# frozen_string_literal: true

# Independent structural validation of the data-plane rows dataset.
# Gem-free (plain `ruby`). Checks, per the model's row contract:
#   1. Every case validates against schema/data-plane-rows.schema.json.
#   2. Contract invariants on every row: 7 columns; column types
#      (int/int/int/string/string-or-null/array-of-strings/string);
#      ordinals are 0-based, gapless, parent-child consistent; depth
#      is parent+1; attribute pairs alternate name/value strings.
#   3. No implementation identifiers in the data.
#
# Usage: ruby tools/validate_rows.rb

require "json"
require_relative "json_schema_subset"

REPO = File.expand_path("..", __dir__)
DATA = File.join(REPO, "tests", "data-plane-rows.json")
SCHEMA = File.join(REPO, "schema", "data-plane-rows.schema.json")

failures = 0

dataset = JSON.parse(File.read(DATA))
unless dataset["schema"].is_a?(Integer) && dataset["schema"] >= 1 &&
    dataset["generator"].is_a?(String) && !dataset["generator"].empty?
  puts "FAIL: dataset provenance missing (schema/generator)"
  failures += 1
end
cases = dataset["cases"]
unless cases.is_a?(Hash) && !cases.empty?
  puts "FATAL: an empty dataset can never look like a pass"
  exit 1
end

schema = JSON.parse(File.read(SCHEMA))

def str_array?(value)
  value.is_a?(Array) && value.all?(String)
end

cases.each do |id, case_data|
  errors = JsonSchemaSubset.validate(schema, case_data)
  errors.each do |e|
    puts "FAIL: #{id} #{e}"
    failures += 1
  end
  next unless case_data.is_a?(Hash) && case_data["rows"].is_a?(Array)

  seen_ordinals = []
  ordinal_parent = {}
  case_data["rows"].each_with_index do |row, i|
    unless row.is_a?(Array) && row.length == 7
      puts "FAIL: #{id} row #{i}: not 7 columns"
      failures += 1
      next
    end
    ordinal, parent, depth, name, ns, pairs, text = row
    unless (ordinal.is_a?(Integer) && parent.is_a?(Integer)) || parent.nil?
      puts "FAIL: #{id} row #{i}: bad ordinal/parent types"
      failures += 1
    end
    unless depth.is_a?(Integer) && name.is_a?(String)
      puts "FAIL: #{id} row #{i}: bad depth/name types"
      failures += 1
    end
    unless ns.nil? || ns.is_a?(String)
      puts "FAIL: #{id} row #{i}: namespace_uri must be string or null"
      failures += 1
    end
    unless str_array?(pairs) && pairs.length.even?
      puts "FAIL: #{id} row #{i}: attribute_pairs must be an even string run"
      failures += 1
    end
    unless text.is_a?(String)
      puts "FAIL: #{id} row #{i}: text must be a string"
      failures += 1
    end

    seen_ordinals << ordinal
    ordinal_parent[ordinal] = parent
    if parent.nil?
      unless depth.zero?
        puts "FAIL: #{id} row #{i}: root depth must be 0"
        failures += 1
      end
    elsif ordinal_parent.key?(parent)
      parent_depth = case_data["rows"][parent][2]
      if parent_depth.is_a?(Integer) && depth != parent_depth + 1
        puts "FAIL: #{id} row #{i}: depth is not parent+1"
        failures += 1
      end
    end
  end

  if seen_ordinals.sort != (0...seen_ordinals.length).to_a
    puts "FAIL: #{id}: ordinals are not 0-based and gapless"
    failures += 1
  end
  roots = seen_ordinals.count { |o| ordinal_parent[o].nil? }
  if roots != 1
    puts "FAIL: #{id}: exactly one root expected, found #{roots}"
    failures += 1
  end
end

blob = JSON.generate(cases)
if blob.match?(/moxml-rs|Moxml::|Leptris|nokogiri/i)
  puts "FAIL: implementation identifiers in the data"
  failures += 1
end

if failures.zero?
  total = cases.values.sum { |c| c["rows"].length }
  puts "ROWS VALIDATION PASS (#{cases.size} cases, #{total} rows)"
else
  puts "ROWS VALIDATION FAIL (#{failures} violations)"
  exit 1
end
