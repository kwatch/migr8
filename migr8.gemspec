#!/usr/bin/ruby

###
### $Release: 0.4.2 $
### $License: MIT License $
### $Copyright: copyright(c) 2013 kuwata-lab.com all rights reserved $
###

require 'rubygems'

spec = Gem::Specification.new do |s|
  ## package information
  s.name        = "migr8"
  s.author      = "makoto kuwata"
  s.email       = "kwa(at)kuwata-lab.com"
  s.rubyforge_project = 'migr8'
  s.version     = "$Release: 0.4.2 $".split()[1]
  s.platform    = Gem::Platform::RUBY
  s.homepage    = "https://github.com/kwatch/migr8/tree/ruby-release"
  s.summary     = "database schema version management tool"
  s.description = <<'END'
Migr8.rb is a database schema version management tool.
* Easy to install, easy to setup, and easy to start
* No configuration file; instead, only two environment variables
* Designed carefully to suit Git or Mercurial
* Supports SQLite3, PostgreSQL, and MySQL
* Written in Ruby (>= 1.8)
END

  ## files
  files = []
  files += Dir.glob('lib/**/*')
  files += Dir.glob('bin/*')
  files += Dir.glob('test/**/*')
  #files += Dir.glob('doc/**/*')
  files += %w[README.md MIT-LICENSE setup.rb migr8.gemspec Rakefile]
  s.files       = files
  s.executables = ['migr8.rb']
  s.bindir      = 'bin'
  s.test_file   = 'test/run_all.rb'
end

# Quick fix for Ruby 1.8.3 / YAML bug   (thanks to Ross Bamford)
if RUBY_VERSION == '1.8.3'
  def spec.to_yaml
    out = super
    out = '--- ' + out unless out =~ /^---/
    out
  end
end

#if $0 == __FILE__
#  Gem::manage_gems
#  Gem::Builder.new(spec).build
#end

spec
