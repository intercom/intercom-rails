# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)

require "intercom-rails/version"

Gem::Specification.new do |s|
  s.name        = "intercom-rails"
  s.version     = IntercomRails::VERSION
  s.authors     = ["Ben McRedmond", "Ciaran Lee", "Darragh Curran",]
  s.email       = ["ben@intercom.io", "ciaran@intercom.io", "darragh@intercom.io"]
  s.homepage    = "http://www.intercom.io"
  s.summary     = %q{Rails helper for emitting javascript script tags for Intercom}
  s.description = %Q{Intercom (https://www.intercom.io) is a customer relationship management and messaging tool for web app owners. This library makes it easier to use the correct javascript tracking code in your rails applications.}

  s.rubyforge_project = "intercom-rails"

  s.files = Dir["{app,config,db,lib}/**/*"] + ["MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency 'activesupport', ">3.0"
  s.add_development_dependency 'rake'
  s.add_development_dependency 'actionpack'
  s.add_development_dependency 'rspec-mocks'
  s.add_development_dependency 'pry'
  s.add_development_dependency 'sinatra'
end
