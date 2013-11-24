# -*- coding: utf-8 -*-

require 'oktest'
require 'migr8'
require 'stringio'
require File.join(File.dirname(File.expand_path(__FILE__)), 'helpers')


Oktest.scope do


  topic Migr8::Application do

    klass = Migr8::Application


    topic '.run()' do

      fixture :app do
        Migr8::Application.new
      end

      spec "[!dcggy] sets Migr8::DEBUG=true when '-d' or '--debug' specified." do |app|
        [
          ["-D"],
          ["--debug"],
        ].each do |args|
          at_exit { Migr8.DEBUG = false }
          sout, serr = Dummy.new.stdouterr do
            Migr8::DEBUG = false
            ok {Migr8::DEBUG} == false
            status = app.run(args)
            ok {Migr8::DEBUG} == true
          end
        end
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
  -D, --debug         : not remove sql file ('migr8/tmp.sql') for debug

Actions:  (default: status)
  readme              : !!READ ME AT FIRST!!
  help [action]       : show help message of action, or list action names
  init                : create necessary files and a table
  hist                : list history of versions
  new                 : create new migration file and open it by $MIGR8_EDITOR
  show [version]      : show migration file with expanding variables
  edit [version]      : open migration file by $MIGR8_EDITOR
  status              : show status
  up                  : apply next migration
  down                : unapply current migration
  redo                : do migration down, and up it again
  apply version ...   : apply specified migrations
  unapply version ... : unapply specified migrations
  delete version ...  : delete unapplied migration file

(ATTENTION!! Run '#{File.basename($0)} readme' at first if you don't know #{File.basename($0)} well.)

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
          expected = "#{Migr8::RELEASE}\n"
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
          ok {pr}.NOT.raise?(Migr8::Util::CommandOptionError)
        end
      end

    end


  end


end
