#!/usr/bin/env rake
require "rubygems"
require "bundler/setup"

require "bundler/gem_tasks"

require 'rspec'
require 'rspec/core/rake_task'

desc "Run all RSpec test examples"
RSpec::Core::RakeTask.new do |spec|
  spec.rspec_opts = ["-c", "-f progress"]
  spec.pattern = 'spec/**/*_spec.rb'
end

task :default => :spec