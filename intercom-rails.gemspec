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

  s.files = Dir["{app,config,db,lib}/**/*"] + ["Rakefile", "README.mdown"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency 'activesupport', '>3.0'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'actionpack', '~> 3.2.22'
  s.add_development_dependency 'test-unit'
  s.add_development_dependency 'rspec', '~> 3.4'
  s.add_development_dependency 'rspec-rails', '~> 3.4'
  s.add_development_dependency 'pry'
  s.add_development_dependency 'sinatra', '~> 1.4.5'
  s.add_development_dependency 'thin', '~> 1.6.4'
  s.add_development_dependency 'tzinfo'
  s.add_development_dependency 'gem-release'
end
