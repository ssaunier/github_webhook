require 'json'
require 'openssl'
require 'active_support/concern'
require 'active_support/core_ext/hash/indifferent_access'

require 'github_webhook/version'
require 'github_webhook/processor'
require 'github_webhook/railtie'

module GithubWebhook
  class <<self
    attr_accessor :logger
  end
end
