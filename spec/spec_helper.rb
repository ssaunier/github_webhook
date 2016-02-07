ENV['RAILS_ENV'] ||= 'test'

require "codeclimate-test-reporter"
CodeClimate::TestReporter.start

require "github_webhook"

# Load support files
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }

RSpec.configure do |config|
  config.order = "random"
end
