# -*- coding: utf-8 -*-

project   = "migr8"
release   = "0.3.0"
copyright = "copyright(c) 2013 kuwata-lab.com all rights reserved"
license   = "MIT-LICENSE"

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


desc "update $Release$"
task :edit do
  files = ['README.md', 'lib/migr8.rb']
  edit_files(files) do |s, filename|
    s.gsub!(/\$Release:.*\$/, "$Release: #{release} $")
    s.gsub!(/\$Release\$/, release)
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
