# -*- encoding: utf-8 -*-
$:.push File.expand_path('../lib', __FILE__)
require 'calabash-cucumber/version'

Gem::Specification.new do |s|
  s.name        = 'calabash-cucumber'
  s.version     = Calabash::Cucumber::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ['Karl Krukow']
  s.email       = ['karl@lesspainful.com']
  s.homepage    = 'http://calaba.sh'
  s.summary     = %q{Client for calabash-ios-server for automated functional testing on iOS}
  s.description = %q{calabash-cucumber drives tests for native iOS apps. You must link your app with calabash-ios-server framework to execute tests.}
  s.files         = `git ls-files`.split("\n").concat(['staticlib/calabash.framework.zip'])
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = 'calabash-ios'
  s.require_paths = ['lib']

  s.add_dependency('cucumber', '~> 1.3.0')
  s.add_dependency('calabash-common', '~> 0.0.1')
  s.add_dependency('json')
  s.add_dependency('edn', '1.0.6')
  s.add_dependency('CFPropertyList','~> 2.2.8')
  s.add_dependency('sim_launcher', '~> 0.4.11')
  s.add_dependency('slowhandcuke')
  s.add_dependency('geocoder', '~>1.1.8')
  s.add_dependency('httpclient', '~> 2.3.3')
  s.add_dependency('bundler', '~> 1.1')
  s.add_dependency('run_loop', '~> 0.2.1')
  s.add_dependency('awesome_print')

  s.add_development_dependency 'rake'
  s.add_development_dependency 'rspec'
  s.add_development_dependency('yard', '~> 0.8.7.4')
  s.add_development_dependency('redcarpet')

end
