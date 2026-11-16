# frozen_string_literal: true

require "json"
require "tmpdir"
require "fileutils"
require "open3"

RSpec.configure do |config|
  config.disable_monkey_patching!
  config.order = :random
end

module SpecSupport
  REPO = File.expand_path("..", __dir__)

  module_function

  # Run a validator against a MUTATED COPY of the real dataset in a
  # scratch dir - real data, real subprocesses, no doubles.
  def run_validator(tool, mutation)
    Dir.mktmpdir do |dir|
      FileUtils.cp_r(File.join(REPO, "tests"), dir)
      FileUtils.cp_r(File.join(REPO, "schema"), dir)
      # The validators resolve the repo relative to their own file, so
      # the copy carries tools/ too - the mutation is what gets read.
      FileUtils.cp_r(File.join(REPO, "tools"), dir)
      mutation&.call(File.join(dir, "tests",
                               "moxml-conformance.json"))
      out, err, status = Open3.capture3(
        "ruby", File.join(dir, "tools", tool),
        chdir: dir
      )
      [out, err, status]
    end
  end
end
