# -*- coding: utf-8 -*-

require 'oktest'
require 'skima'


Oktest.scope do


  topic Skima::Util::CommandOptionDefinition do

    klass = Skima::Util::CommandOptionDefinition
    errclass = Skima::Util::CommandOptionDefinitionError


    topic '.new()' do

      spec "parses definition string of short and long options without arg." do
        [
          "-h, --help: show help",
          "-h,--help: show help",
          "  -h, --help :   show help ",
        ].each do |defstr|
          x = klass.new(defstr)
          ok {x.short} == 'h'
          ok {x.long}  == 'help'
          ok {x.name}  == 'help'
          ok {x.arg}   == nil
          ok {x.desc}  == 'show help'
          ok {x.arg_required} == false
        end
      end

      spec "parses definition string of short and long options with required arg." do
        [
          "-a, --action=name: action name.",
          "-a,--action=name: action name.",
          "  -a,   --action=name  :  action name. ",
        ].each do |defstr|
          x = klass.new(defstr)
          ok {x.short} == 'a'
          ok {x.long}  == 'action'
          ok {x.name}  == 'action'
          ok {x.arg}   == 'name'
          ok {x.desc}  == 'action name.'
          ok {x.arg_required} == true
        end
      end

      spec "parses definition string of short and long options with optional arg." do
        [
          "-i, --indent[=N]: indent depth (default 2).",
          "-i,--indent[=N]: indent depth (default 2).",
          "  -i,  --indent[=N]  :  indent depth (default 2). ",
        ].each do |defstr|
          x = klass.new(defstr)
          ok {x.short} == 'i'
          ok {x.long}  == 'indent'
          ok {x.name}  == 'indent'
          ok {x.arg}   == 'N'
          ok {x.desc}  == 'indent depth (default 2).'
          ok {x.arg_required} == nil
        end
      end

      spec "parses definition string of short-only options without arg." do
        [
          "-q: be quiet",
          "  -q  :   be quiet ",
        ].each do |defstr|
          x = klass.new(defstr)
          ok {x.short} == 'q'
          ok {x.long}  == nil
          ok {x.name}  == 'q'
          ok {x.arg}   == nil
          ok {x.desc}  == 'be quiet'
          ok {x.arg_required} == false
        end
      end

      spec "parses definition string of short-only options with required arg." do
        [
          "-a name: action name.",
          "  -a  name  :  action name. ",
        ].each do |defstr|
          x = klass.new(defstr)
          ok {x.short} == 'a'
          ok {x.long}  == nil
          ok {x.name}  == 'a'
          ok {x.arg}   == 'name'
          ok {x.desc}  == 'action name.'
          ok {x.arg_required} == true
        end
      end

      spec "parses definition string of short-only options with optional arg." do
        [
          "-i[N]: indent depth (default 2).",
          "  -i[N]  :  indent depth (default 2). ",
        ].each do |defstr|
          x = klass.new(defstr)
          ok {x.short} == 'i'
          ok {x.long}  == nil
          ok {x.name}  == 'i'
          ok {x.arg}   == 'N'
          ok {x.desc}  == 'indent depth (default 2).'
          ok {x.arg_required} == nil
        end
      end

      spec "parses definition string of long-only options without arg." do
        [
          "--verbose: be verbose",
          "  --verbose  :  be verbose ",
        ].each do |defstr|
          x = klass.new(defstr)
          ok {x.short} == nil
          ok {x.long}  == 'verbose'
          ok {x.name}  == 'verbose'
          ok {x.arg}   == nil
          ok {x.desc}  == 'be verbose'
          ok {x.arg_required} == false
        end
      end

      spec "parses definition string of long-only options with required arg." do
        [
          "--action=name: action name.",
          "  --action=name  :  action name. ",
        ].each do |defstr|
          x = klass.new(defstr)
          ok {x.short} == nil
          ok {x.long}  == 'action'
          ok {x.name}  == 'action'
          ok {x.arg}   == 'name'
          ok {x.desc}  == 'action name.'
          ok {x.arg_required} == true
        end
      end

      spec "parses definition string of long-only options with optional arg." do
        [
          "--indent[=N]: indent depth (default 2).",
          "  --indent[=N]  :  indent depth (default 2). ",
        ].each do |defstr|
          x = klass.new(defstr)
          ok {x.short} == nil
          ok {x.long}  == 'indent'
          ok {x.name}  == 'indent'
          ok {x.arg}   == 'N'
          ok {x.desc}  == 'indent depth (default 2).'
          ok {x.arg_required} == nil
        end
      end

      spec "detects '#name' notation to override option name." do
        #
        [
          "-h #usage : show usage.",
        ].each do |defstr|
          x = klass.new(defstr)
          ok {x.short} == 'h'
          ok {x.long}  == nil
          ok {x.name}  == 'usage'
          ok {x.arg}   == nil
          ok {x.desc}  == 'show usage.'
          ok {x.arg_required} == false
        end
        #
        [
          "-h, --help  #usage : show usage.",
        ].each do |defstr|
          x = klass.new(defstr)
          ok {x.short} == 'h'
          ok {x.long}  == 'help'
          ok {x.name}  == 'usage'
          ok {x.arg}   == nil
          ok {x.desc}  == 'show usage.'
          ok {x.arg_required} == false
        end
        #
        [
          "--help  #usage : show usage.",
        ].each do |defstr|
          x = klass.new(defstr)
          ok {x.short} == nil
          ok {x.long}  == 'help'
          ok {x.name}  == 'usage'
          ok {x.arg}   == nil
          ok {x.desc}  == 'show usage.'
          ok {x.arg_required} == false
        end
        #
        [
          "-a name #command : action name.",
        ].each do |defstr|
          x = klass.new(defstr)
          ok {x.short} == 'a'
          ok {x.long}  == nil
          ok {x.name}  == 'command'
          ok {x.arg}   == 'name'
          ok {x.desc}  == 'action name.'
          ok {x.arg_required} == true
        end
        #
        [
          "--action=name #command : action name.",
        ].each do |defstr|
          x = klass.new(defstr)
          ok {x.short} == nil
          ok {x.long}  == 'action'
          ok {x.name}  == 'command'
          ok {x.arg}   == 'name'
          ok {x.desc}  == 'action name.'
          ok {x.arg_required} == true
        end
        #
        [
          "-i, --indent[=N] #width : indent width (default 2).",
        ].each do |defstr|
          x = klass.new(defstr)
          ok {x.short} == 'i'
          ok {x.long}  == 'indent'
          ok {x.name}  == 'width'
          ok {x.arg}   == 'N'
          ok {x.desc}  == 'indent width (default 2).'
          ok {x.arg_required} == nil
        end
        #
        [
          "-i[N] #width : indent width (default 2).",
        ].each do |defstr|
          x = klass.new(defstr)
          ok {x.short} == 'i'
          ok {x.long}  == nil
          ok {x.name}  == 'width'
          ok {x.arg}   == 'N'
          ok {x.desc}  == 'indent width (default 2).'
          ok {x.arg_required} == nil
        end
        #
        [
          "--indent[=N] #width : indent width (default 2).",
        ].each do |defstr|
          x = klass.new(defstr)
          ok {x.short} == nil
          ok {x.long}  == 'indent'
          ok {x.name}  == 'width'
          ok {x.arg}   == 'N'
          ok {x.desc}  == 'indent width (default 2).'
          ok {x.arg_required} == nil
        end
      end

      spec "raises error when failed to parse definition string." do
        pr = proc { klass.new("-h, --help:show help") }
        ok {pr}.raise?(errclass, "'-h, --help:show help': invalid definition.")
      end

    end


    topic '#usage()' do

      spec "[!xd9do] returns option usage with specified width." do
        optdef = klass.new("-h, --help: show help")
        ok {optdef.usage(15)} == "-h, --help     : show help"
        ok {optdef.usage()}   == "-h, --help          : show help"
        optdef = klass.new("-h: show help")
        ok {optdef.usage()}   == "-h                  : show help"
        optdef = klass.new("--help: show help")
        ok {optdef.usage()}   == "--help              : show help"
        #
        optdef = klass.new("-a, --action=name: action name")
        ok {optdef.usage(15)} == "-a, --action=name: action name"
        ok {optdef.usage()}   == "-a, --action=name   : action name"
        optdef = klass.new("-a name: action name")
        ok {optdef.usage()}   == "-a name             : action name"
        optdef = klass.new("--action=name: action name")
        ok {optdef.usage()}   == "--action=name       : action name"
        #
        optdef = klass.new("-i, --indent[=N]: indent width")
        ok {optdef.usage(15)} == "-i, --indent[=N]: indent width"
        ok {optdef.usage()}   == "-i, --indent[=N]    : indent width"
        optdef = klass.new("-i[N]: indent width")
        ok {optdef.usage()}   == "-i[N]               : indent width"
        optdef = klass.new("--indent[=N]: indent width")
        ok {optdef.usage()}   == "--indent[=N]        : indent width"
      end

    end

  end


  topic Skima::Util::CommandOptionParser do

    klass = Skima::Util::CommandOptionParser
    errclass = Skima::Util::CommandOptionError


    topic '#add()' do

      spec "[!tm89j] parses definition string and adds optdef object." do
        parser = klass.new
        parser.add("-h, --help: show help")
        parser.add("-a, --action=name: action name.")
        ok {parser.optdefs.length} == 2
        ok {parser.optdefs[0].short} == 'h'
        ok {parser.optdefs[0].long}  == 'help'
        ok {parser.optdefs[0].arg}   == nil
        ok {parser.optdefs[1].short} == 'a'
        ok {parser.optdefs[1].long}  == 'action'
        ok {parser.optdefs[1].arg}   == 'name'
      end

      spec "[!00kvl] returns self." do
        parser = klass.new
        ret = parser.add("-h, --help: show help")
        ok {ret}.same?(parser)
      end

    end


    topic '#parse()' do

      fixture :parser do
        parser = klass.new
        parser.add("-h, --help        : show help")
        parser.add("-V   #version     : show version")
        parser.add("-a, --action=name : action name")
        parser.add("-i, --indent[=N]  : indent width (default N=2)")
        parser
      end

      spec "returns options parsed." do
        |parser|
        args = "-hVi4 -a print foo bar".split(' ')
        options = parser.parse(args)
        ok {options} == {'help'=>true, 'version'=>true, 'indent'=>'4', 'action'=>'print'}
        ok {args} == ["foo", "bar"]
      end

      spec "parses short options." do
        |parser|
        # short options
        args = "-hVi4 -a print foo bar".split(' ')
        options = parser.parse(args)
        ok {options} == {'help'=>true, 'version'=>true, 'indent'=>'4', 'action'=>'print'}
        ok {args} == ["foo", "bar"]
        #
        args = "-hi foo bar".split(' ')
        options = parser.parse(args)
        ok {options} == {'help'=>true, 'indent'=>true}
        ok {args} == ["foo", "bar"]
      end

      spec "parses long options." do
        |parser|
        # long options
        args = "--help --action=print --indent=4 foo bar".split(' ')
        options = parser.parse(args)
        ok {options} == {'help'=>true, 'indent'=>'4', 'action'=>'print'}
        ok {args} == ["foo", "bar"]
        #
        args = "--indent foo bar".split(' ')
        options = parser.parse(args)
        ok {options} == {'indent'=>true}
        ok {args} == ["foo", "bar"]
      end

      spec "[!2jo9d] stops to parse options when '--' found." do |parser|
        args = ["-h", "--", "-V", "--action=print", "foo", "bar"]
        options = parser.parse(args)
        ok {options} == {'help'=>true}
        ok {args} == ["-V", "--action=print", "foo", "bar"]
      end

      spec "[!7pa2x] raises error when invalid long option." do |parser|
        pr1 = proc { parser.parse(["--help?", "aaa"]) }
        ok {pr1}.raise?(errclass, "--help?: invalid option format.")
        pr2 = proc { parser.parse(["---help", "aaa"]) }
        ok {pr2}.raise?(errclass, "---help: invalid option format.")
      end

      spec "[!sj0cv] raises error when unknown long option." do |parser|
        pr = proc { parser.parse(["--foobar", "aaa"]) }
        ok {pr}.raise?(errclass, "--foobar: unknown option.")
      end

      spec "[!a7qxw] raises error when argument required but not provided." do |parser|
        pr = proc { parser.parse(["--action", "foo", "bar"]) }
        ok {pr}.raise?(errclass, "--action: argument required.")
      end

      spec "[!8eu9s] raises error when option takes no argument but provided." do |parser|
        pr = proc { parser.parse(["--help=true", "foo", "bar"]) }
        ok {pr}.raise?(errclass, "--help=true: unexpected argument.")
      end

      spec "[!cfjp3] raises error when argname is 'N' but argval is not an integer." do |parser|
        parser.add("-n, --num=N: number")
        pr = proc { parser.parse(["--num=314"]) }
        ok {pr}.NOT.raise?(Exception)
        pr = proc { parser.parse(["--num=3.14"]) }
        ok {pr}.raise?(errclass, "--num=3.14: integer expected.")
        #
        pr = proc { parser.parse(["--indent=4"]) }
        ok {pr}.NOT.raise?(Exception)
        pr = proc { parser.parse(["--indent=4i"]) }
        ok {pr}.raise?(errclass, "--indent=4i: integer expected.")
      end


      spec "[!dtbdd] uses option name instead of long name when option name specified." do |parser|
        pr = proc { parser.parse(["--help=true", "foo", "bar"]) }
        ok {pr}.raise?(errclass, "--help=true: unexpected argument.")
      end

      spec "[!7mp75] sets true as value when argument is not provided." do |parser|
        args = ["--help", "foo", "bar"]
        options = parser.parse(args)
        ok {options} == {'help'=>true}
        ok {args} == ["foo", "bar"]
      end

      spec "[!8aaj0] raises error when unknown short option provided." do |parser|
        args = ["-hxV", "foo"]
        pr = proc { parser.parse(args) }
        ok {pr}.raise?(errclass, "-x: unknown option.")
      end

      case_when "[!mnwxw] when short option takes no argument..." do

        spec "[!8atm1] sets true as value." do |parser|
          args = ["-hV", "foo", "bar"]
          options = parser.parse(args)
          ok {options} == {'help'=>true, 'version'=>true}
          ok {args} == ["foo", "bar"]
        end

      end

      case_when "[!l5mee] when short option takes required argument..." do

        spec "[!crvxx] uses following string as argument." do |parser|
          [
            ["-aprint", "foo", "bar"],
            ["-a", "print", "foo", "bar"],
          ].each do |args|
            options = parser.parse(args)
            ok {options} == {'action'=>'print'}
            ok {args} == ["foo", "bar"]
          end
        end

        spec "[!7t6l3] raises error when no argument provided." do |parser|
          pr = proc { parser.parse(["-a"]) }
          ok {pr}.raise?(errclass, "-a: argument required.")
        end

        spec "[!yzr2p] argument must be an integer if arg name is 'N'." do |parser|
          parser.add("-w, --weight=N: weight value.")
          pr = proc { parser.parse(["-w", "314", "hoo"]) }
          ok {pr}.NOT.raise?(Exception)
          #
          pr = proc { parser.parse(["-w", "3.14", "hoo"]) }
          ok {pr}.raise?(errclass, "-w 3.14: integer expected.")
        end

      end

      case_when "[!pl97z] when short option takes optional argument..." do

        spec "[!4k3zy] uses following string as argument if provided." do |parser|
          args = ["-hi4", "foo", "bar"]
          options = parser.parse(args)
          ok {options} == {'help'=>true, 'indent'=>'4'}
          ok {args} == ["foo", "bar"]
        end

        spec "[!9k2ip] uses true as argument value if not provided." do |parser|
          args = ["-hi", "foo", "bar"]
          options = parser.parse(args)
          ok {options} == {'help'=>true, 'indent'=>true}
          ok {args} == ["foo", "bar"]
        end

        spec "[!6oy04] argument must be an integer if arg name is 'N'." do |parser|
          parser.add("-w, --weight[=N]: weight value.")
          pr = proc { parser.parse(["--weight=314", "hoo"]) }
          ok {pr}.NOT.raise?(Exception)
          #
          pr = proc { parser.parse(["-w3.14", "hoo"]) }
          ok {pr}.raise?(errclass, "-w3.14: integer expected.")
        end

      end

      spec "[!35eof] returns parsed options." do |parser|
        [
          ["-hVi4", "--action=print", "foo", "bar"],
          ["--indent=4", "-hVa", "print", "foo", "bar"],
        ].each do |args|
          options = parser.parse(args)
          ok {options} == {'help'=>true, 'version'=>true, 'indent'=>'4', 'action'=>'print'}
          ok {args} == ["foo", "bar"]
        end
      end

    end


    topic '#usage()' do

      spec "[!w9v9c] returns usage string of all options." do
        parser = klass.new
        parser.add("-h, --help        : show help")
        parser.add("-V   #version     : show version")
        parser.add("-a, --action=name : action name")
        parser.add("-i, --indent[=N]  : indent width (default N=2)")
        #
        expected = <<'END'
-h, --help          : show help
-V                  : show version
-a, --action=name   : action name
-i, --indent[=N]    : indent width (default N=2)
END
        ok {parser.usage()} == expected
        #
        expected = <<'END'
-h, --help      : show help
-V              : show version
-a, --action=name: action name
-i, --indent[=N]: indent width (default N=2)
END
        ok {parser.usage(16)} == expected
      end

      spec "[!i0uvr] adds indent when specified." do
        parser = klass.new
        parser.add("-h, --help        : show help")
        parser.add("--quiet           : be quiet")
        #
        expected = <<'END'
  -h, --help          : show help
  --quiet             : be quiet
END
        ok {parser.usage(nil, '  ')} == expected
      end

      spec "[!lbjai] skips options when desc is empty." do
        parser = klass.new
        parser.add("-h, --help        : show help")
        parser.add("-D, --debug[=N]   : ")
        parser.add("--quiet           : be quiet")
        #
        expected = <<'END'
-h, --help          : show help
--quiet             : be quiet
END
        ok {parser.usage()} == expected
      end


    end


  end


end
