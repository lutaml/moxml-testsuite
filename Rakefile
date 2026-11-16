# frozen_string_literal: true

MOXML_DIR = ENV.fetch("MOXML_PATH", File.expand_path("../moxml", __dir__))

desc "Prove the dataset's cases are identical to the moxml reference export"
task :validate do
  sh "ruby #{File.join(__dir__, 'tools', 'validate.rb')}"
end

desc "Validate every row against schema/test.schema.json (fail-closed subset)"
task :schema do
  sh "ruby #{File.join(__dir__, 'tools', 'validate_schema.rb')}"
end

desc "All validations (identity + schema)"
task all: %i[validate schema]

namespace :corpus do
  desc "Regenerate tests/ from the moxml reference checkout (MOXML_PATH)"
  task :regen do
    sh "cd #{MOXML_DIR.shellescape} && " \
       "bundle exec rake conformance:export >/dev/null"
    cp File.join(MOXML_DIR, "conformance", "moxml-conformance.json"),
       File.join(__dir__, "tests", "moxml-conformance.json")
    puts "corpus: regenerated tests/moxml-conformance.json from #{MOXML_DIR}"
  end

  desc "Fail if the dataset drifts from the reference (same as validate)"
  task :check do
    sh "ruby #{File.join(__dir__, 'tools', 'validate.rb')}"
  end
end

desc "The tool-guard spec suite"
task :spec do
  sh "bundle exec rspec"
end

task default: :all
