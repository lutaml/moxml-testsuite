# frozen_string_literal: true

require "spec_helper"
require "open3"

CliResult = Struct.new(:stdout, :stderr, :success)

RSpec.describe "the cli certification runner" do
  let(:exe) { File.expand_path("../../exe/moxml-testsuite", __dir__) }
  let(:lib) { File.expand_path("../../lib", __dir__) }

  def run_cli(*args)
    stdout, stderr, status =
      Open3.capture3(RbConfig.ruby, "-I", lib, exe, *args)
    CliResult.new(stdout, stderr, status.success?)
  end

  it "certifies the default engine and exits 0" do
    result = run_cli
    expect(result.success).to be(true)
    expect(result.stdout).to include("moxml-testsuite (facade: Moxml::TestSuite::Reference)")
    expect(result.stdout).to include("PASS c14n (14 cases)")
    expect(result.stderr).to be_empty
  end

  it "certifies a pinned adapter" do
    result = run_cli("--adapter", "nokogiri")
    expect(result.success).to be(true)
    expect(result.stdout).to include("PASS serialization (20 cases)")
  end

  it "drives a family subset" do
    result = run_cli("--families", "c14n")
    expect(result.success).to be(true)
    expect(result.stdout).to include("PASS c14n (14 cases)")
    expect(result.stdout).not_to include("serialization")
  end

  it "exits 2 loudly on an unavailable adapter" do
    result = run_cli("--adapter", "nonexistent")
    expect(result.success).to be(false)
    expect(result.stderr).to include("nonexistent")
  end

  it "shows help and exits 0" do
    result = run_cli("--help")
    expect(result.success).to be(true)
    expect(result.stdout).to include("Usage: moxml-testsuite")
    expect(result.stdout).to include("--adapter")
    expect(result.stderr).to be_empty
  end
end
