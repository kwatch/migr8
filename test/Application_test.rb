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

      spec "[!dcggy] sets Skima::DEBUG=true when '-d' or '--debug' specified." do |app|
        [
          ["-D"],
          ["--debug"],
        ].each do |args|
          at_exit { Skima.DEBUG = false }
          sout, serr = Dummy.new.stdouterr do
            Skima::DEBUG = false
            ok {Skima::DEBUG} == false
            status = app.run(args)
            ok {Skima::DEBUG} == true
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
  -D, --debug         : not remove sql file ('skima/tmp.sql') for debug

Actions:  (default: status)
  intro               : !!RUN THIS ACTION AT FIRST!!
  help [action]       : show help message of action, or list action names
  init                : create necessary files and a table
  hist                : list history of versions
  new                 : create new migration file and open it by $SKIMA_EDITOR
  edit [version]      : open migration file by $SKIMA_EDITOR
  status              : show status
  up                  : apply next migration
  down                : unapply current migration
  redo                : do migration down, and up it again
  apply version ...   : apply specified migrations
  unapply version ... : unapply specified migrations

(ATTENTION!! Run '#{File.basename($0)} intro' at first if you don't know Application_test.rb well.)

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
