# frozen_string_literal: true

Gem::Specification.new do |s|
  s.name        = 'dendroid'
  s.version     = begin
    libpath = ::File.expand_path(__FILE__) + ::File::SEPARATOR
    path = ::File.dirname(libpath) + ::File::SEPARATOR
    ::File.read("#{path}version.txt").strip
  end
  s.summary     = 'WIP. A Ruby implementation of an Earley parser'
  s.description = 'WIP. A Ruby implementation of an Earley parser'
  s.authors     = ['Dimitri Geshef']
  s.email       = 'famished.tiger@yahoo.com'
  s.files       = Dir['bin/dendroid',
                      'lib/*.*',
                      'lib/**/*.rb',
                      'spec/**/*.rb',
                      '.rubocop.yml',
                      'CHANGELOG.md',
                      'dendroid.gemspec',
                      'LICENSE',
                      'Rakefile',
                      'README.md',
                      'version.txt'
  ]
  s.required_ruby_version = '>=3.1'
  s.homepage   = 'https://github.com/famished-tiger/Dendroid'
  s.license    = 'MIT'
end
