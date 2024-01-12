# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)

require "intercom-rails/version"

Gem::Specification.new do |s|
  s.name        = "intercom-rails"
  s.version     = IntercomRails::VERSION
  s.authors     = ["Ben McRedmond", "Ciaran Lee", "Darragh Curran",]
  s.license     = "MIT"
  s.email       = ["ben@intercom.io", "ciaran@intercom.io", "darragh@intercom.io"]
  s.homepage    = "http://www.intercom.io"
  s.summary     = %q{Rails helper for emitting javascript script tags for Intercom}
  s.description = %Q{Intercom (https://www.intercom.io) is a customer relationship management and messaging tool for web app owners. This library makes it easier to use the correct javascript tracking code in your rails applications.}

  s.rubyforge_project = "intercom-rails"

  s.files = Dir["{app,config,db,lib}/**/*"] + ["Rakefile", "README.md"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency 'activesupport', '~> 7.0.8'
  s.add_development_dependency 'actionpack', '~> 7.0.8'
  s.add_development_dependency 'gem-release'
  s.add_development_dependency 'pry'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'rexml', '~> 3.2'
  s.add_development_dependency 'rspec', '~> 3.12'
  s.add_development_dependency 'rspec-rails', '~> 6.0.2'
  s.add_development_dependency 'sinatra', '~> 3.2.0'
  s.add_development_dependency 'thin', '~> 1.8.2'
  s.add_development_dependency 'tzinfo'
end
