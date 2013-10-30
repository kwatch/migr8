# -*- coding: utf-8 -*-

###
### skeema.py -- DB schema version management tool
###
### $Release: 0.0.0 $
### $License: MIT License $
### $Copyright: (c) kuwata-lab.com all rights reserverd $
###


module Skeema

  RELEASE = "$Release: 0.0.0 $".split(' ')[1]


  class Application

    def run(args)
      parser = new_cmdopt_parser()
      options = parser.parse(args)   # may raise CommandOptionError
      #; [!ktlay] prints help message and exit when '-h' or '--help' specified.
      if options['help']
        $stdout << self.usage(parser)
        return 0
      end
      #; [!n0ubh] prints version string and exit when '-v' or '--version' specified.
      if options['version']
        $stdout << RELEASE << "\n"
        return 0
      end
      #; [!saisg] returns 0 as status code when succeeded.
      return 0
    end

    def usage(parser)
      script = File.basename($0)
      s = "Usage: #{script} [common-options] action [options] [...]\n"
      s << parser.usage(20, '  ')
      return s
    end

    def self.main(args=nil)
      #; [!cy0yo] uses ARGV when args is not passed.
      args = ARGV if args.nil?
      app = self.new
      begin
        status = app.run(args)
      #; [!maomq] command-option error is cached and not raised.
      rescue Util::CommandOptionError => ex
        script = File.basename($0)
        $stderr << "#{script}: #{ex.message}\n"
        status = 1
      end
      #; [!t0udo] returns status code (0: ok, 1: error).
      return status
    end

    private

    def new_cmdopt_parser
      parser = Util::CommandOptionParser.new
      parser.add("-h, --help:      show help")
      parser.add("-v, --version:   show version")
      parser.add("-D, --debug:")
      return parser
    end

  end


  module Util


    class CommandOptionDefinitionError < StandardError
    end


    class CommandOptionError < StandardError
    end


    class CommandOptionDefinition

      attr_accessor :short, :long, :arg, :name, :desc, :arg_required

      def initialize(defstr)
        case defstr
        when /\A--(\w[-\w]*)(?:\[=(.+?)\]|=(\S.*?))?(?:\s+\#(\w+))?\s*:(?:\s+(.*)?)?\z/
          short, long, arg, name, desc = nil, $1, ($2 || $3), $4, $5
          arg_required = $2 ? nil : $3 ? true : false
        when /\A-(\w),\s*--(\w[-\w]*)(?:\[=(.+?)\]|=(\S.*?))?(?:\s+\#(\w+))?\s*:(?:\s+(.*)?)?\z/
          short, long, arg, name, desc = $1, $2, ($3 || $4), $5, $6
          arg_required = $3 ? nil : $4 ? true : false
        when /\A-(\w)(?:\[(.+?)\]|\s+([^\#\s].*?))?(?:\s+\#(\w+))?\s*:(?:\s+(.*)?)?\z/
          short, long, arg, name, desc = $1, nil, ($2 || $3), $4, $5
          arg_required = $2 ? nil : $3 ? true : false
        else
          raise CommandOptionDefinitionError.new("'#{defstr}': invalid definition.")
        end
        name ||= (long || short)
        #
        @short = _strip(short)
        @long  = _strip(long)
        @arg   = _strip(arg)
        @name  = _strip(name)
        @desc  = _strip(desc)
        @arg_required = arg_required
      end

      def usage(width=20)
        argreq = @arg_required
        if @short && @long
          s = "-#{@short}, --#{@long}"           if argreq == false
          s = "-#{@short}, --#{@long}=#{@arg}"   if argreq == true
          s = "-#{@short}, --#{@long}[=#{@arg}]" if argreq == nil
        elsif @long
          s = "--#{@long}"           if argreq == false
          s = "--#{@long}=#{@arg}"   if argreq == true
          s = "--#{@long}[=#{@arg}]" if argreq == nil
        elsif @short
          s = "-#{@short}"           if argreq == false
          s = "-#{@short} #{@arg}"   if argreq == true
          s = "-#{@short}[#{@arg}]"  if argreq == nil
        end
        #; [!xd9do] returns option usage with specified width.
        return "%-#{width}s: %s" % [s, @desc]
      end

      private

      def _strip(str)
        return nil if str.nil?
        str = str.strip
        return str.empty? ? nil : str
      end

    end


    class CommandOptionParser

      attr_reader :optdefs

      def initialize
        @optdefs = []
      end

      def add(optdef)
        #; [!tm89j] parses definition string and adds optdef object.
        optdef = CommandOptionDefinition.new(optdef) if optdef.is_a?(String)
        @optdefs << optdef
        #; [!00kvl] returns self.
        return self
      end

      def parse(args)
        options = {}
        while ! args.empty? && args[0] =~ /\A-/
          optstr = args.shift
          if optstr =~ /\A--/
            #; [!2jo9d] stops to parse options when '--' found.
            break if optstr == '--'
            #; [!7pa2x] raises error when invalid long option.
            optstr =~ /\A--(\w[-\w]+)(?:=(.*))?\z/  or
              raise CommandOptionError.new("#{optstr}: invalid option format.")
            #; [!sj0cv] raises error when unknown long option.
            long, argval = $1, $2
            optdef = @optdefs.find {|x| x.long == long }  or
              raise CommandOptionError.new("#{optstr}: unknown option.")
            #; [!a7qxw] raises error when argument required but not provided.
            if optdef.arg_required == true && argval.nil?
              raise CommandOptionError.new("#{optstr}: argument required.")
            #; [!8eu9s] raises error when option takes no argument but provided.
            elsif optdef.arg_required == false && argval
              raise CommandOptionError.new("#{optstr}: unexpected argument.")
            end
            #; [!dtbdd] uses option name instead of long name when option name specified.
            #; [!7mp75] sets true as value when argument is not provided.
            options[optdef.name] = argval.nil? ? true : argval
          elsif optstr =~ /\A-/
            i = 1
            while i < optstr.length
              ch = optstr[i]
              #; [!8aaj0] raises error when unknown short option provided.
              optdef = @optdefs.find {|x| x.short == ch }  or
                raise CommandOptionError.new("-#{ch}: unknown option.")
              #; [!mnwxw] when short option takes no argument...
              if optdef.arg_required == false      # no argument
                #; [!8atm1] sets true as value.
                options[optdef.name] = true
                i += 1
              #; [!l5mee] when short option takes required argument...
              elsif optdef.arg_required == true    # required argument
                #; [!crvxx] uses following string as argument.
                argval = optstr[(i+1)..-1]
                if argval.empty?
                  #; [!7t6l3] raises error when no argument provided.
                  ! args.empty?  or
                    raise CommandOptionError.new("-#{ch}: argument required.")
                  argval = args.shift
                end
                options[optdef.name] = argval
                break
              #; [!pl97z] when short option takes optional argument...
              elsif optdef.arg_required == nil     # optional argument
                #; [!4k3zy] uses following string as argument if provided.
                argval = optstr[(i+1)..-1]
                if argval.empty?
                  #; [!9k2ip] uses true as argument value if not provided.
                  argval = true
                end
                options[optdef.name] = argval
                break
              else
                raise "** unreachable"
              end
            end#while
          end#if
        end#while
        #; [!35eof] returns parsed options.
        return options
      end#def

      def usage(width=20, indent='')
        width = 20 if width.nil?
        #; [!w9v9c] returns usage string of all options.
        s = ""
        @optdefs.each do |optdef|
          #; [!i0uvr] adds indent when specified.
          #; [!lbjai] skips options when desc is empty.
          s << "#{indent}#{optdef.usage(width)}\n" if optdef.desc
        end
        return s
      end

    end#class

  end


end
