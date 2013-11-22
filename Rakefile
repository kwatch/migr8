# -*- coding: utf-8 -*-

project   = "migr8"
release   = "0.2.1"
copyright = "copyright(c) 2013 kuwata-lab.com all rights reserved"
license   = "MIT License"

require 'fileutils'
include FileUtils

require 'rake/clean'
CLEAN.include("build/#{project}-#{release}")
CLOBBER.include("build")


task :default => :test

def _do_test
  Dir.glob('test/*_test.rb').each do |fname|
    sh "ruby #{fname} -sp"
  end
end

desc "do test"
task :test do
  _do_test()
end

desc "do test for 1.8.6, 1.8.7, and 1.9.2"
task :test_all do
  orig_path = ENV['PATH']
  %w[1.8.6-p369 1.8.7-p334 1.9.2-p180].each do |ruby_ver|
    ruby_path = "/usr/local/ruby/#{ruby_ver}/bin"
    ENV['PATH'] = ruby_path + ':' + orig_path
    puts "*** ruby_path=#{ruby_path}"
    sh "ruby -v"
    _do_test()
  end
end


desc "embed 'README.md' into 'lib/migr8.rb'"
task :embed_readme do
  content = File.read('README.md')
  content.gsub!(/^    /, '')
  content.gsub!(/\n\n<!--.*\n-->\n/m, '')
  File.open('lib/migr8.rb', 'r+') do |f|
    text = f.read()
    text.sub!(/('README_DOCUMENT'\n)(.*)(^README_DOCUMENT\n)/m,
              "'README_DOCUMENT'\n#{content}README_DOCUMENT\n")
    f.rewind()
    f.truncate(0)
    f.write(text)
  end
end


def edit_files(*filenames, &block)
  filenames.flatten.each do |fname|
    Dir.glob(fname).each do |fpath|
      next unless File.file?(fpath)
      s = File.open(fpath, 'rb') {|f| f.read() }
      s = block.arity == 2 ? yield(s, fpath) : yield(s)
      File.open(fpath, 'wb') {|f| f.write(s) }
    end
  end
end


desc "update '$Release$', '$License$', and '$Copyright$'"
task :edit do
  files = ['README.md', 'MIT-LICENSE', 'lib/*.rb', 'bin/*.rb', 'test/*.rb', 'migr8.gemspec']
  edit_files(files) do |s, filename|
    next s if filename == 'test/oktest.rb'
    next s if filename == 'Rakefile'
    s.gsub!(/\$Release:.*\$/,   "$Release: #{release} $")
    s.gsub!(/\$License:.*\$/,   "$License: #{license} $")
    s.gsub!(/\$Copyright:.*\$/, "$Copyright: #{copyright} $")
    s.gsub!(/\$Release\$/,   release)
    s.gsub!(/\$License\$/,   license)
    s.gsub!(/\$Copyright\$/, copyright)
    s
  end
end


desc "copy 'oktest.rb' into 'test/'"
task :oktest => "test/oktest.rb"


file "test/oktest.rb" => File.expand_path("~/src/oktest/ruby/lib/oktest.rb") do |t|
  cp t.prerequisites, "test"
end

#task "availables" do |t|
#  methods = t.methods.sort - Object.new.methods
#  $stderr.puts "\033[0;31m*** debug: methods=#{methods.inspect}\033[0m"
#end


desc "generates rubygems package"
task :gem => :dist do
  dir = "dist/#{project}-#{release}"
  Dir.chdir dir do
    sh "gem build migr8.gemspec"
  end
  mv Dir.glob("#{dir}/migr8-#{release}.gem"), "dist"
  puts "**"
  puts "** created: dist/migr8-#{release}.gem"
  puts "**"
end


desc "create 'dist' directory and copy files to it"
task :dist do
  dir = "dist/#{project}-#{release}"
  files = %w[README.md MIT-LICENSE migr8.gemspec Rakefile setup.rb]
  rm_rf dir
  mkdir_p dir
  mkdir_p "#{dir}/bin"
  mkdir_p "#{dir}/lib"
  mkdir_p "#{dir}/test"
  cp files, dir
  cp Dir.glob("lib/*"), "#{dir}/lib"
  cp Dir.glob("lib/*"), "#{dir}/bin"
  cp Dir.glob("test/*"), "#{dir}/test"
  chmod 0644, *Dir.glob("#{dir}/lib/*")
  chmod 0755, *Dir.glob("#{dir}/bin/*")
  Dir.chdir dir do
    sh "rake edit"
  end
end
