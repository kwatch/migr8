# -*- coding: utf-8 -*-

require 'oktest'
require 'skima'
require 'stringio'
require File.join(File.dirname(File.absolute_path(__FILE__)), 'helpers')


Oktest.scope do


  topic Skima::Application do

    klass = Skima::Application


    topic '.run()' do

      fixture :app do
        Skima::Application.new
      end

      spec "[!ktlay] prints help message and exit when '-h' or '--help' specified." do |app|
        [
          ["-h", "foo"],
          ["--help", "foo"],
        ].each do |args|
          sout, serr = Dummy.new.stdouterr do
            status = app.run(args)
            ok {status} == 0
            ok {args} == ["foo"]
          end
          expected = <<END
#{File.basename($0)} -- database schema version management tool

Usage: #{File.basename($0)} [global-options] [action [options] [...]]
  -h, --help          : show help
  -v, --version       : show version

Actions:  (default: status)
  navi                : !!RUN THIS ACTION AT FIRST!!
  help [action]       : show help message of action, or list action names
  init                : create necessary files and a table
  hist                : list history of versions
  new                 : create new migration file and open it by $SKIMA_EDITOR
  edit [version]      : open migration file by $SKIMA_EDITOR
  status              : show status
  up                  : apply a next migration
  down                : unapply current migration
  redo                : do migration down, and up it again
  apply version ...   : apply specified migrations
  unapply version ... : unapply specified migrations

Setup:
  $ export SKIMA_COMMAND='psql -q -U user1 database1'   # for PostgreSQL
  $ export SKIMA_EDITOR='emacsclient'                   # or 'vi', 'open', etc
  $ skima.rb init
END
          ok {sout} == expected
          ok {serr} == ""
        end
      end

      spec "[!n0ubh] prints version string and exit when '-v' or '--version' specified." do |app|
        [
          ["-v", "foo", "bar"],
          ["--version", "foo", "bar"],
        ].each do |args|
          sout, serr = Dummy.new.stdouterr do
            status = app.run(args)
            ok {status} == 0
            ok {args} == ["foo", "bar"]
          end
          expected = "#{Skima::RELEASE}\n"
          ok {sout} == expected
          ok {serr} == ""
        end
      end

      spec "[!saisg] returns 0 as status code when succeeded." do |app|
        [
          #["foo", "bar"],
          [],
        ].each do |args|
          sout, serr = Dummy.new.stdouterr do
            status = app.run(args)
            ok {status} == 0
            ok {args} == [] # ["foo", "bar"]
          end
          ok {sout}.NOT == ""
          ok {serr} == ""
        end
      end

    end


    topic '.main()' do

      spec "[!cy0yo] uses ARGV when args is not passed." do
        bkup = ARGV.dup
        ARGV[0..-1] = ["-h", "-v", "foo", "bar"]
        Dummy.new.stdouterr do
          klass.main()
          ok {ARGV} == ["foo", "bar"]
        end
        ARGV[0..-1] = bkup
      end

      spec "[!t0udo] returns status code (0: ok, 1: error)." do
        Dummy.new.stdouterr do
          status = klass.main(["-hv"])
          ok {status} == 0
          status = klass.main(["-hx"])
          ok {status} == 1
        end
      end

      spec "[!maomq] command-option error is cached and not raised." do
        Dummy.new.stdouterr do
          pr = proc { klass.main(["-hx"]) }
          ok {pr}.NOT.raise?(Skima::Util::CommandOptionError)
        end
      end

    end


  end


end
