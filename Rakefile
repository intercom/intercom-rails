#!/usr/bin/env rake

begin
  require 'bundler/setup'
rescue LoadError
  puts 'You must `gem install bundler` and `bundle install` to run rake tasks'
end

Bundler::GemHelper.install_tasks

require 'rake/testtask'

Rake::TestTask.new("test") do |test|
  test.libs << 'lib'
  test.libs << 'test'

  test.test_files = FileList['test/**/*_test.rb']
  test.warning = false
  test.verbose = true
end

task :default => :test
