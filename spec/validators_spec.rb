# frozen_string_literal: true

require "spec_helper"
require_relative "../tools/json_schema_subset"

RSpec.describe "the validators" do
  include SpecSupport

  it "accept the committed dataset untouched" do
    out, _err, status = run_validator("validate_schema.rb", nil)
    expect(status.exitstatus).to eq(0), out
    expect(out).to include("SCHEMA VALIDATION PASS (177 rows, 7 families)")
  end

  it "reject a dataset that is not valid JSON" do
    out, _err, status = run_validator(
      "validate_schema.rb",
      ->(path) { File.write(path, "{ not json") },
    )
    expect(status.exitstatus).to eq(1)
    expect(out).to include("not valid JSON")
  end

  it "reject an empty family" do
    out, _err, status = run_validator(
      "validate_schema.rb",
      ->(path) do
        d = JSON.parse(File.read(path))
        d["cases"]["c14n"] = []
        File.write(path, JSON.generate(d))
      end,
    )
    expect(status.exitstatus).to eq(1)
    expect(out).to include("family c14n missing or empty")
  end

  it "reject rows that answer against the committed shape" do
    out, _err, status = run_validator(
      "validate_schema.rb",
      ->(path) do
        d = JSON.parse(File.read(path))
        d["cases"]["builtin_lexical"][0]["lexical"] = 12_345
        File.write(path, JSON.generate(d))
      end,
    )
    expect(status.exitstatus).to eq(1)
    expect(out).to include("builtin_lexical[0] $: matches 0 oneOf branches")
  end

  it "reject undeclared families" do
    out, _err, status = run_validator(
      "validate_schema.rb",
      ->(path) do
        d = JSON.parse(File.read(path))
        d["cases"]["secret_family"] = []
        File.write(path, JSON.generate(d))
      end,
    )
    expect(status.exitstatus).to eq(1)
    expect(out).to include("undeclared families present")
  end

  it "reject duplicate ids in an id-carrying family" do
    out, _err, status = run_validator(
      "validate_schema.rb",
      ->(path) do
        d = JSON.parse(File.read(path))
        d["cases"]["c14n"][1]["id"] = d["cases"]["c14n"][0]["id"]
        File.write(path, JSON.generate(d))
      end,
    )
    expect(status.exitstatus).to eq(1)
    expect(out).to include("duplicate ids")
  end

  it "reject implementation class names in the data" do
    out, _err, status = run_validator(
      "validate_schema.rb",
      ->(path) do
        d = JSON.parse(File.read(path))
        d["cases"]["c14n"][0]["canonical"] = "Moxml::C14n made this"
        File.write(path, JSON.generate(d))
      end,
    )
    expect(status.exitstatus).to eq(1)
    expect(out).to include("implementation class names")
  end

  it "reject an empty dataset outright" do
    out, _err, status = run_validator(
      "validate_schema.rb",
      ->(path) do
        d = JSON.parse(File.read(path))
        d["cases"] = d["cases"].to_h { |k, _| [k, []] }
        File.write(path, JSON.generate(d))
      end,
    )
    expect(status.exitstatus).to eq(1)
    expect(out).to include("an empty dataset can never look like a pass")
  end
end
