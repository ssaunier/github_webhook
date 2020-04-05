# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'github_webhook/version'

Gem::Specification.new do |spec|
  spec.name          = "github_webhook"
  spec.version       = GithubWebhook::VERSION
  spec.authors       = ["Sebastien Saunier"]
  spec.email         = ["seb@saunier.me"]
  spec.summary       = %q{Process GitHub Webhooks in your Rails app (Controller mixin)}
  spec.description   = spec.summary
  spec.homepage      = "https://github.com/ssaunier/github_webhook"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "rack", ">= 1.3"
  spec.add_dependency "activesupport", ">= 4"
  spec.add_dependency "railties", ">= 4"

  spec.add_development_dependency "rake", "~> 10.1"
  spec.add_development_dependency "rspec", "~> 2.14"
  spec.add_development_dependency "codeclimate-test-reporter", "~> 1.0"
  spec.add_development_dependency "appraisal"
end
