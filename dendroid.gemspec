# frozen_string_literal: true

Gem::Specification.new do |s|
  s.name        = 'dendroid'
  s.version     = begin
                    LIBPATH = ::File.expand_path( __FILE__) + ::File::SEPARATOR
                    PATH = ::File.dirname(LIBPATH) + ::File::SEPARATOR
                    ::File.read(PATH + 'version.txt').strip
                  end
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
  s.homepage   = 'https://github.com/famished-tiger/Dendroid'
  s.license    = 'MIT'
end
