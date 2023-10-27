# frozen_string_literal: true

Gem::Specification.new do |s|
  s.name        = 'dendroid'
  s.version     = '0.0.0'
  s.summary     = 'Dendroid. TODO'
  s.description = 'WIP. A Ruby implementation of a Earley parser'
  s.authors     = ['Dimitri Geshef']
  s.email       = 'famished.tiger@yahoo.com'
  s.files       = Dir['bin/dendroid',
    'lib/*.*',
    'lib/**/*.rb',
    'spec/**/*.rb',
    '.rubocop.yml',
    'dendroid.gemspec',
    'LICENSE',
    'Rakefile',
    'README.md',
    'version.txt'
  ]
  s.homepage   = 'https://rubygems.org/gems/dendroid'
  s.license    = 'MIT'
end
