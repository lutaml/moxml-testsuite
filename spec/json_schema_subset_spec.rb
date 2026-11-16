# frozen_string_literal: true

require "spec_helper"
require_relative "../tools/json_schema_subset"

RSpec.describe "the JSON-Schema subset engine" do
  it "fails closed on keywords it does not implement" do
    expect do
      JsonSchemaSubset.validate({ "format" => "email" }, "x")
    end.to raise_error(JsonSchemaSubset::UnsupportedKeyword, /format/)
  end

  it "resolves $defs refs" do
    schema = {
      "$defs" => { "positive" => { "type" => "integer", "enum" => [1, 2] } },
      "$ref" => "#/$defs/positive",
    }
    expect(JsonSchemaSubset.validate(schema, 1)).to be_empty
    expect(JsonSchemaSubset.validate(schema, 3)).not_to be_empty
    expect(JsonSchemaSubset.validate(schema, "1")).not_to be_empty
  end

  it "enforces additionalProperties: false against properties" do
    schema = {
      "type" => "object",
      "additionalProperties" => false,
      "properties" => { "a" => { "type" => "string" } },
    }
    expect(JsonSchemaSubset.validate(schema, { "a" => "x" })).to be_empty
    expect(JsonSchemaSubset.validate(schema,
                                     { "a" => "x", "b" => 1 })).not_to be_empty
  end
end
