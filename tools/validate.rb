#!/usr/bin/env ruby
# frozen_string_literal: true

# Identity contract: the committed dataset's cases are IDENTICAL to
# what the moxml reference implementation exports from its case
# tables (lib/moxml/*_cases.rb + the XSD rule tables). Gem-free in
# THIS repo - the reference implementation is exercised in ITS OWN
# checkout (MOXML_PATH env or the sibling checkout), never loaded
# here, so this validator cannot inherit the exporter's logic.
#
# Identity is case-level: the `cases` payload must be equal; the
# `generator` field is provenance (the exporting moxml version) and
# may legitimately differ from a sibling checkout at main.
#
# Usage: ruby tools/validate.rb [MOXML_PATH]
# Exits nonzero on any violation.

require "json"
require "shellwords"

REPO = File.expand_path("..", __dir__)
MOXML = ARGV[0] ||
  ENV.fetch("MOXML_PATH", File.expand_path("../../moxml", __dir__))
DATA = File.join(REPO, "tests", "moxml-conformance.json")

unless File.directory?(MOXML)
  warn "FAIL: no moxml checkout at #{MOXML} - provide MOXML_PATH"
  exit 1
end

def canonical_cases(path)
  dataset = JSON.parse(File.read(path))
  JSON.generate(dataset["cases"])
end

committed = canonical_cases(DATA)

exported_path = File.join(MOXML, "conformance", "moxml-conformance.json")
export_cmd = "cd #{MOXML.shellescape} && " \
             "bundle exec rake conformance:export >/dev/null"
system(export_cmd) || begin
  warn "FAIL: the moxml checkout failed to run `rake conformance:export`"
  exit 1
end
exported = canonical_cases(exported_path)

if committed == exported
  cases = JSON.parse(File.read(DATA))["cases"]
  total = cases.values.sum(&:length)
  puts "IDENTITY PASS (#{total} cases match the moxml export)"
else
  warn "FAIL: the committed dataset drifts from the moxml export"
  warn "  regenerate with: rake corpus:regen"
  exit 1
end
