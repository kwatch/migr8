# -*- coding: utf-8 -*-

###
### skeema.py -- DB schema version management tool
###
### $Release: 0.0.0 $
### $License: MIT License $
### $Copyright: (c) kuwata-lab.com all rights reserverd $
###


module Skeema


  module Util


    class CommandOptionDefinitionError < StandardError
    end


    class CommandOptionError < StandardError
    end


    class CommandOptionDefinition

      attr_accessor :short, :long, :arg, :name, :help, :arg_required

      def initialize(defstr)
        case defstr
        when /\A--(\w[-\w]*)(?:\[=(.+?)\]|=(\S.*?))?(?:\s+\#(\w+))?\s*:(?:\s+(.*)?)?\z/
          short, long, arg, name, help = nil, $1, ($2 || $3), $4, $5
          arg_required = $2 ? nil : $3 ? true : false
        when /\A-(\w),\s*--(\w[-\w]*)(?:\[=(.+?)\]|=(\S.*?))?(?:\s+\#(\w+))?\s*:(?:\s+(.*)?)?\z/
          short, long, arg, name, help = $1, $2, ($3 || $4), $5, $6
          arg_required = $3 ? nil : $4 ? true : false
        when /\A-(\w)(?:\[(.+?)\]|\s+([^\#\s].*?))?(?:\s+\#(\w+))?\s*:(?:\s+(.*)?)?\z/
          short, long, arg, name, help = $1, nil, ($2 || $3), $4, $5
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
        @help  = _strip(help)
        @arg_required = arg_required
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

    end#class

  end


end
