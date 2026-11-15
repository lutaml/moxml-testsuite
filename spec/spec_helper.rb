# frozen_string_literal: true

require "bundler/setup"
require "moxml"
require "moxml/testsuite"

RSpec.configure do |config|
  config.disable_monkey_patching!
  config.order = :random
  config.seed = 42_424_242
end
