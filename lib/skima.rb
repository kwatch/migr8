#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

###
### skima.py -- DB schema version management tool
###
### $Release: 0.0.0 $
### $License: MIT License $
### $Copyright: (c) kuwata-lab.com all rights reserverd $
###

require 'yaml'
require 'open3'
require 'etc'


module Skima

  RELEASE = "$Release: 0.0.0 $".split(' ')[1]


  class SkimaError < StandardError
  end

  class CommandSetupError < SkimaError
  end

  class SQLExecutionError < SkimaError
  end

  class HistoryFileError < SkimaError
  end

  class MigrationFileError < SkimaError
  end

  class UpgradeFailedError < SkimaError
  end

  class DowngradeFailedError < SkimaError
  end

  class RepositoryError < SkimaError
  end


  class Migration

    attr_accessor :version, :author, :desc, :vars, :up, :down
    attr_accessor :applied_at

    def initialize(version=nil, author=nil, desc=nil)
      #; [!y4dy3] takes version, author, and desc arguments.
      @version = version
      @author  = author
      @desc    = desc
      @vars    = {}
      @up      = ''
      @down    = ''
    end

    def applied?
      #; [!ebzct] returns false when @applied_at is nil, else true.
      return ! @applied_at.nil?
    end

    def up_statement
      #; [!cfp34] returns nil when 'up' is not set.
      return @up unless @up
      #; [!6gaxb] returns 'up' string expanding vars in it.
      return Util::Expander.expand_str(@up, @vars)
    end

    def down_statement
      #; [!e45s1] returns nil when 'down' is not set.
      return @down unless @down
      #; [!0q3nq] returns 'down' string expanding vars in it.
      return Util::Expander.expand_str(@down, @vars)
    end

    def applied_at_or(default)
      #; [!zazux] returns default arugment when not applied.
      return default unless applied?
      #; [!fxb4y] returns @applied_at with replacing separator by 'T'.
      return @applied_at.split(/\./)[0].sub(/ /, 'T')
    end

    def filepath
      #; [!l9t5k] returns nil when version is not set.
      return nil unless @version
      #; [!p0d9q] returns filepath of migration file.
      return Repository.new(nil).migration_filepath(@version)
    end

    def self.load_from(filepath)
      #; [!fbea5] loads data from file and returns migration object.
      data = File.open(filepath) {|f| YAML.load(f) }
      mig = self.new(data['version'], data['author'], data['desc'])
      #; [!sv21s] expands values of 'vars'.
      mig.vars = Util::Expander.expand_vars(data['vars'])
      #; [!32ns3] not expand both 'up' and 'down'.
      mig.up   = data['up']
      mig.down = data['down']
      return mig
    end

  end


  class Repository

    HISTORY_FILEPATH  = 'skima/history.txt'
    HISTORY_TABLE     = '_skima_history'
    MIGRATION_DIRPATH = 'skima/migrations/'

    attr_reader :dbms

    def initialize(dbms=nil)
      @dbms = dbms
    end

    def history_filepath()
      return HISTORY_FILEPATH
    end

    def migration_filepath(version)
      return "#{MIGRATION_DIRPATH}#{version}.yaml"
    end

    def parse_history_file()
      fpath = history_filepath()
      tuples = []
      File.open(fpath) do |f|
        i = 0
        f.each do |line|
          i += 1
          line.strip!
          next if line =~ /\A\#/
          next if line.empty?
          line =~ /\A([-\w]+)[ \t]*\# \[(.*)\][ \t]*(.*)\z/  or
            raise HistoryFileError.new("File '#{fpath}', line #{i}: invalid format.\n    #{line}")
          version, author, desc = $1, $2, $3
          tuples << [version, author, desc]
        end
      end
      return tuples
    end

    def migrations_in_history_file(applied_migrations_dict=nil)
      dict = applied_migrations_dict  # {version=>applied_at}
      applied = nil
      tuples = parse_history_file()
      fpath = history_filepath()
      migrations = tuples.collect {|version, author, desc|
        mig = load_migration(version)
        mig.version == version  or
          $stderr << "# WARNING: #{version}: version in history file is not match to #{fpath}\n"
        mig.author == author  or
          $stderr << "# WARNING: #{version}: author in history file is not match to #{fpath}\n"
        mig.desc == desc  or
          $stderr << "# WARNING: #{version}: description in history file is not match to #{fpath}\n"
        mig.applied_at = applied.applied_at if dict && (applied = dict.delete(mig.version))
        mig
      }
      return migrations
    end

    def migrations_in_history_table()
      return @dbms.get_migrations()
    end

    def get_migrations()
      ## applied migrations
      mig_applied = {}   # {version=>migration}
      migrations_in_history_table().each {|mig| mig_applied[mig.version] = mig }
      ## migrations in history file
      mig_hist = migrations_in_history_file()
      mig_hist.each do |migration|
        mig = mig_applied.delete(migration.version)
        migration.applied_at = mig.applied_at if mig
      end
      ##
      return mig_hist, mig_applied
    end

    def load_migration(version)
      fpath = migration_filepath(version)
      return nil unless File.file?(fpath)
      return Migration.load_from(fpath)
    end

    def apply_migrations(migs)
      @dbms.apply_migrations(migs)
    end

    def unapply_migrations(migs)
      @dbms.unapply_migrations(migs)
    end

    def upgrade(n)
      ## applied migrations
      migs_dict = {}  # {version=>migration}
      migrations_in_history_table().each {|mig| migs_dict[mig.version] = mig }
      ## migrations in history file
      migs_hist = migrations_in_history_file()
      ## index of current version
      curr = migs_hist.rindex {|mig| migs_dict.key?(mig.version) }
      ## error when unapplied older version exists
      if curr
        j = migs_hist.index {|mig| ! migs_dict.key?(mig.version) }
        raise UpgradeFailedError.new("apply #{migs_hist[j].version} at first.") if j && j < curr
      end
      ## unapplied migrations
      migs_unapplied = curr ? migs_hist[(curr+1)..-1] : migs_hist
      ## apply n migrations
      migs_to_apply = n.nil? ? migs_unapplied : migs_unapplied[0...n]
      if migs_to_apply.empty?
        puts "## (nothing to apply)"
      else
        #migs_to_apply.each do |mig|
        #  puts "## applying #{mig.version}  \# [#{mig.author}] #{mig.desc}"
        #  apply_migration(mig)
        #end
        apply_migrations(migs_to_apply)
      end
    end

    def downgrade(n)
      ## applied migrations
      migs_dict = {}  # {version=>migration}
      migrations_in_history_table().each {|mig| migs_dict[mig.version] = mig }
      ## migrations in history file
      migs_hist = migrations_in_history_file()
      ## index of current version
      curr = migs_hist.rindex {|mig| migs_dict.key?(mig.version) }
      ## error when unapplied older version exists in target migrations
      migs_applied = curr ? migs_hist[0..curr] : []
      migs_applied.all? {|mig| migs_dict.key?(mig.version) }  or
        raise DowngradeFailedError.new("version '#{migs_hist[j].version}' is not applied yet.")
      ## unapply n migrations
      migs_to_unapply = n && n < migs_applied.length ? migs_applied[-n..-1] \
                                                     : migs_applied
      if migs_to_unapply.empty?
        puts "## (nothing to unapply)"
      else
        #migs_to_unapply.reverse_each do |mig|
        #  puts "## unapplying #{mig.version}  \# [#{mig.author}] #{mig.desc}"
        #  unapply_migration(mig)
        #end
        unapply_migrations(migs_to_unapply.reverse())
      end
    end

    def new_version
      while true
        version = _new_version()
        break unless File.file?(migration_filepath(version))
      end
      return version
    end

    def _new_version
      version = ''
      s = VERSION_CHARS
      r = 0..(s.length-1)
      version << s[rand(r)] << s[rand(r)] << s[rand(r)] << s[rand(r)]
      d = VERSION_DIGITS
      r = 0..(d.length-1)
      version << d[rand(r)] << d[rand(r)] << d[rand(r)] << d[rand(r)]
      return version
    end

    VERSION_CHARS  = ('a'..'z').to_a - ['l']
    VERSION_DIGITS = ('0'..'9').to_a - ['1']

    def init()
      verbose = true
      ## create directory
      path = migration_filepath('_dummy_')
      dirs = []
      while ! (path = File.dirname(path)).empty? && path != '.' && path != '/'
        dirs << path
      end
      dirs.reverse_each do |dir|
        if ! File.directory?(dir)
          puts "$ mkdir #{dir}" if verbose
          Dir.mkdir(dir)
        end
      end
      ## create history file
      fpath = history_filepath()
      if ! File.file?(fpath)
        magic = '# -*- coding: utf-8 -*-'
        puts "$ echo '#{magic}' > #{fpath}" if verbose
        File.open(fpath, 'w') {|f| f.write(magic+"\n") }
      end
      ## create history table
      @dbms.create_history_table()
    end

    def init?
      return false unless File.file?(history_filepath())
      return false unless File.directory?(File.dirname(migration_filepath('_')))
      return false unless @dbms.history_table_exist?
      return true
    end

    def history_file_exist?
      fpath = history_filepath()
      return File.file?(fpath)
    end

    def history_file_empty?
      fpath = history_filepath()
      return true unless File.file?(fpath)
      exist_p = File.open(fpath, 'rb') {|f|
        f.any? {|line| line =~ /\A\s*\w+/ }
      }
      return ! exist_p
    end

    def create_migration(desc, author=nil, opts={})
      mig = Migration.new(new_version(), author || Etc.getlogin(), desc)
      content = render_migration_file(opts)
      File.open(mig.filepath, 'wb') {|f| f.write(content) }
      File.open(history_filepath(), 'ab') {|f| f.write(to_line(mig)+"\n") }
      return mig
    end

    protected

    def to_line(mig)  # :nodoc:
      return "%-10s # [%s] %s" % [mig.version, mig.author, mig.desc]
    end

    def render_migration_file(mig, opts={})  # :nodoc:
      plain_p = opts[:plain]
      skeleton_for_up   = plain_p ? '' : @dbms.skeleton_for_up
      skeleton_for_down = plain_p ? '' : @dbms.skeleton_for_down
      s = <<END
# -*- coding: utf-8 -*-

version:     #{mig.version}
desc:        #{mig.desc}
author:      #{mig.author}
vars:
END
      if dbms
        s << <<END
  - table:   table123
  - column:  column123
  - index:   ${table}_${column}_idx
  - unique:  ${table}_${column}_unq
END
      end
      s << <<END

up: |
#{skeleton_for_up}
down: |
#{skeleton_for_down}
END
      return s
    end

    public

    def inspection(n=5)
      mig_hist, mig_dict = get_migrations()
      pos = mig_hist.length - n - 1
      i = mig_hist.index {|mig| ! mig.applied? }  # index of oldest unapplied
      j = mig_hist.rindex {|mig| mig.applied? }   # index of newest applied
      start = i.nil? ? pos : [i - 1, pos].min
      start = 0 if start < 0
      if mig_hist.empty?
        status = "no migrations"
        recent = nil
      elsif i.nil?
        status = "all applied"
        recent = mig_hist[start..-1]
      elsif j.nil?
        status = "nothing applied"
        recent = mig_hist[0..-1]
      elsif i < j
        status = "YOU MUST APPLY #{mig_hist[i].version} AT FIRST!"
        recent = mig_hist[start..-1]
      else
        count = mig_hist.length - i
        status = "there are #{count} migrations to apply"
        status = "there is a migration to apply" if count == 1
        recent = mig_hist[start..-1]
      end
      missing = mig_dict.empty? ? nil : mig_dict.values
      return {:status=>status, :recent=>recent, :missing=>missing}
    end

  end


  module DBMS

    def self.detect_by_command(command)
      return Base.detect_by_command(command)
    end


    class Base

      attr_reader :command
      attr_accessor :history_table
      attr_accessor :sqltmpfile    # :nodoc:

      def initialize(command=nil)
        @command = command
        @history_table = Repository::HISTORY_TABLE
        @sqltmpfile = 'skima/tmp.sql'
      end

      def execute_sql(sql, cmdopt=nil)
        output, error = Open3.popen3("#{@command} #{cmdopt}") do |sin, sout, serr|
          sin.write(sql)
          sin.close()   # important!
          [sout.read(), serr.read()]
        end
        #if output && ! output.empty?
        #  $stdout << output
        #end
        if error && ! error.empty?
          $stderr << error
          raise SQLExecutionError.new
        end
        return output
      end

      def run_sql(sql, opts={})
        verbose = opts[:verbose]
        tmpfile = sqltmpfile()
        puts "$ cat <<_END_ > #{tmpfile}"   if verbose
        puts sql                            if verbose
        puts "_END_"                        if verbose
        File.open(tmpfile, 'w') {|f| f.write(sql) }
        puts "$ #{@command} < #{tmpfile}"   if verbose
        ok = system("#{@command} < #{tmpfile}")
        ok  or
          raise SQLExecutionError.new("Failed to run sql ('#{tmpfile}').")
        File.unlink(tmpfile)
      end

      def create_history_table()
        return false if history_table_exist?
        sql = _history_table_statement()
        run_sql(sql, :verbose=>true)
        return true
      end

      def _history_table_statement()
        return <<END
CREATE TABLE #{history_table()} (
  id           INTEGER       PRIMARY KEY,
  version      VARCHAR(40)   NOT NULL UNIQUE,
  author       VARCHAR(40)   NOT NULL,
  description  VARCHAR(255)  NOT NULL,
  statement    TEXT          NOT NULL,
  applied_at   TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP
);
END
      end
      protected :_history_table_statement

      def history_table_exist?
        raise NotImplementedError.new("#{self.class.name}#history_table_exist?: not implemented yet.")
      end

      def get_migrations()
        cmdopt = ""
        separaotr = "|"
        return _get_girations(cmdopt, separator)
      end

      def _get_migrations(cmdopt, separator)
        sql = "SELECT version, applied_at, author, description FROM #{history_table()} ORDER BY id;"
        output = execute_sql(sql, cmdopt)
        migs = []
        output.each_line do |line|
          line.strip!
          break if line.empty?
          version, applied_at, author, desc = line.strip.split(separator, 4)
          mig = Migration.new(version.strip, author.strip, desc.strip)
          mig.applied_at = applied_at ? applied_at.split(/\./)[0] : nil
          migs << mig
        end
        return migs
      end
      protected :_get_migrations

      def _echo_message(msg)
        raise NotImplementedError.new("#{self.class.name}#_echo_message(): not implemented yet.")
      end
      protected :_echo_message

      def _applying_sql(mig)
        msg = "## applying #{mig.version}  \# [#{mig.author}] #{mig.desc}"
        stmt = mig.up_statement
        sql = <<END
---------------------------------------- applying #{mig.version} ----------
#{_echo_message(msg)}
-----
#{stmt};
-----
INSERT INTO #{@history_table} (version, author, description, statement)
VALUES ('#{q(mig.version)}', '#{q(mig.author)}', '#{q(mig.desc)}', '#{q(stmt)}');
END
        return sql
      end
      protected :_applying_sql

      def _unapplying_sql(mig)
        msg = "## unapplying #{mig.version}  \# [#{mig.author}] #{mig.desc}"
        stmt = mig.down_statement
        sql = <<END
---------------------------------------- unapplying #{mig.version} ----------
#{_echo_message(msg)}
-----
#{stmt}
-----
DELETE FROM #{@history_table} where version = '#{mig.version}';
END
        return sql
      end
      protected :_unapplying_sql

      def apply_migrations(migs)
        _do_migrations(migs) {|mig| _applying_sql(mig) }
      end

      def unapply_migrations(migs)
        _do_migrations(migs) {|mig| _unapplying_sql(mig) }
      end

      def _do_migrations(migs)
        sql = ""
        sql << "BEGIN; /** start transaction **/\n\n"
        sql << migs.collect {|mig| yield mig }.join("\n")
        sql << "\nCOMMIT; /** end transaction **/\n"
        run_sql(sql)
      end
      protected :_do_migrations

      def q(str)
        return str.gsub(/\'/, "''")
      end
      protected :q

      def skeleton_for_up()
        raise NotImplementedError.new("#{self.class.name}#skeleton_for_up(): not implemented yet.")
      end

      def skeleton_for_down()
        raise NotImplementedError.new("#{self.class.name}#skeleton_for_down(): not implemented yet.")
      end

      ##

      @subclasses = []

      def self.inherited(klass)
        @subclasses << klass
      end

      def self.detect_by_command(command)
        klazz = @subclasses.find {|klass| command =~ klass.const_get(:PATTERN) }
        return klazz ? klazz.new(command) : nil
      end

    end


    class SQLite3 < Base
      SYMBOL  = 'sqlite3'
      PATTERN = /\bsqlite3\b/

      def execute_sql(sql, cmdopt=nil)
        preamble = ".bail ON\n"
        return super(preamble+sql, cmdopt)
      end

      def run_sql(sql, opts={})
        preamble = ".bail ON\n"
        super(preamble+sql, opts)
      end

      protected

      def _histrory_table_statement()
        sql = super
        sql = sql.sub(/PRIMARY KEY/, 'PRIMARY KEY AUTOINCREMENT')
        sql = sql.sub(/ TIMESTAMP /, ' DATETIME  ')
        return sql
      end

      def _echo_message(msg)
        return ".print '#{q(msg)}'"
      end

      public

      def history_table_exist?
        table = history_table()
        output = execute_sql(".table #{table}")
        return output.include?(table)
      end

      def get_migrations()
        migrations = _get_migrations("-list", /\|/)
        return migrations
      end

      def skeleton_for_up()
        return <<END
  ---
  --- create table or index
  ---
  create table ${table} (
    id          integer        primary key autoincrement,
    version     integer        not null default 0,
    name        string         not null unique,
    created_at  timestamp      not null default current_timestamp,
    updated_at  timestamp,
    deleted_at  timestamp
  );
  create index ${index} on ${table}(${column});
  ---
  --- add column
  ---
  alter table ${table} add column ${column} string not null default '';
END
      end

      def skeleton_for_down()
        return <<END
  ---
  --- drop table or index
  ---
  drop table ${table};
  drop index ${index};
END
      end

    end


    class PostgreSQL < Base
      SYMBOL  = 'postgres'
      PATTERN = /\bpsql\b/

      def execute_sql(sql, cmdopt=nil)
        preamble = "SET client_min_messages TO WARNING;\n"
        return super(preamble+sql, cmdopt)
      end

      def run_sql(sql, opts={})
        preamble = "SET client_min_messages TO WARNING;\n"+
                   "\\set ON_ERROR_STOP ON\n"
        super(preamble+sql, opts)
      end

      protected

      def _history_table_statement()
        sql = super
        sql = sql.sub(/INTEGER/, 'SERIAL ')
        sql = sql.sub('CURRENT_TIMESTAMP', 'TIMEOFDAY()::TIMESTAMP')
        return sql
      end

      def _echo_message(msg)
        return "\\echo '#{q(msg)}'"
      end

      public

      def history_table_exist?
        table = history_table()
        output = execute_sql("\\dt #{table}")
        return output.include?(table)
      end

      def get_migrations()
        migrations = _get_migrations("-qt", / \| /)
        return migrations
      end

      def skeleton_for_up()
        return <<END
  ---
  --- create table or index
  ---
  create table ${table} (
    id          serial         primary key,
    version     integer        not null default 0,
    name        varchar(255)   not null unique,
    created_at  timestamp      not null default current_timestamp,
    updated_at  timestamp,
    deleted_at  timestamp
  );
  create index ${index} on ${table}(${column});
  ---
  --- add column or unique constraint
  ---
  alter table ${table} add column ${column} varchar(255) not null unique;
  alter table ${table} add constraint ${unique} unique(${column});
  ---
  --- change column
  ---
  alter table ${table} rename column ${column} to ${new_column};
  alter table ${table} alter column ${column} type varchar(255);
  alter table ${table} alter column ${column} set not null;
  alter table ${table} alter column ${column} set default current_date;
END
      end

      def skeleton_for_down()
        return <<END
  ---
  --- drop table or index
  ---
  drop table ${table};
  drop index ${index};
  ---
  --- drop column or unique constraint
  ---
  alter table ${table} drop column ${column};
  alter table ${table} drop constraint ${unique};
  ---
  --- revert column
  ---
  alter table ${table} rename column ${new_column} to ${column};
  alter table ${table} alter column ${column} type varchar(255);
  alter table ${table} alter column ${column} drop not null;
  alter table ${table} alter column ${column} drop default;
END
      end

    end


  end


  module Actions


    class Action
      NAME = nil
      DESC = nil
      OPTS = []
      ARGS = nil

      def parser
        name = self.class.const_get(:NAME)
        opts = self.class.const_get(:OPTS)
        parser = Util::CommandOptionParser.new("#{name}:")
        opts.each {|cmdopt| parser.add(cmdopt) }
        return parser
      end

      def parse(args)
        return parser().parse(args)
      end

      def usage
        klass = self.class
        name = klass.const_get(:NAME)
        args = klass.const_get(:ARGS)
        desc = klass.const_get(:DESC)
        s = args ? "#{name} #{args}" : "#{name}"
        head = "#{File.basename($0)} #{s}  : #{desc}\n"
        return head+parser().usage(20, '  ')
      end

      def short_usage()
        klass = self.class
        name = klass.const_get(:NAME)
        args = klass.const_get(:ARGS)
        desc = klass.const_get(:DESC)
        s = args ? "#{name} #{args}" : "#{name}"
        return "  %-20s: %s\n" % [s, desc]
      end

      def run(options, args)
        raise NotImplementedError.new("#{self.class.name}#run(): not implemented yet.")
      end

      def cmdopterr(*args)
        return Util::CommandOptionError.new(*args)
      end

      def get_command
        cmd = ENV['SKIMA_COMMAND'] || ''
        ! cmd.empty?  or
          raise CommandSetupError.new("$SKIMA_COMMAND is empty. Please set it at first.\n" +
                                      "  Example: (MacOSX, Unix)\n" +
                                      "      $ export SKIMA_COMMAND='psql -q -U user dbname'\n" +
                                      "  Example: (Windows)\n" +
                                      "      C:\\> set SKIMA_COMMAND='psql -q -U user dbname'\n")
        return cmd
      end

      def repository(dbms=nil)
        return @repository || begin
                                cmd = get_command()
                                dbms = DBMS.detect_by_command(cmd)
                                repo = Repository.new(dbms)
                                _check(repo, dbms) if _should_check?
                                repo
                              end
      end

      private

      def _should_check?   # :nodoc:
        true
      end

      def _check(repo, dbms)   # :nodoc:
        script = File.basename($0)
        unless dbms.history_table_exist?
          $stderr << <<END
##
## ERROR: history table not created.
## (Please run '#{script} navi' or '#{script} init' at first.)
##
END
          raise RepositoryError.new("#{dbms.history_table}: table not found.")
        end
        unless repo.history_file_exist?
          $stderr << <<END
##
## ERROR: history file not found.
## (Please run '#{script} navi' or '#{script} init' at first.)
##
END
          raise RepositoryError.new("#{repo.history_filepath}: not found.")
        end
      end

      public

      @subclasses = []

      def self.inherited(subclass)
        @subclasses << subclass
      end

      def self.subclasses
        @subclasses
      end

      def self.find_by_name(name)
        return @subclasses.find {|cls| cls.const_get(:NAME) == name }
      end

      protected

      def _recommend_to_set_SKIMA_EDITOR(action)  # :nodoc:
        msg = <<END
## ERROR: Failed to #{action} migration file.
## Plase set $SKIMA_EDITOR in order to open migration file automatically.
## Example:
##   $ export SKIMA_EDITOR='vi'                   # for vi
##   $ export SKIMA_EDITOR='emacsclient'          # for emacs
##   $ export SKIMA_EDITOR='open -a TextMate'     # for MacOSX
END
        $stderr << msg
      end

    end


    class NaviAction < Action
      NAME = "navi"
      DESC = "!!RUN THIS ACTION AT FIRST!!"
      OPTS = []
      ARGS = nil

      attr_accessor :forced

      def run(options, args)
        msg = navi_for_newbie(File.basename($0))
        $stderr << msg
      end

      private

      def _should_check?
        false
      end

      def navi_for_newbie(script)
        msg = ""
        repo = repository()
        #
        command = ENV['SKIMA_COMMAND'].to_s.strip
        command = nil if command.empty?
        editor  = ENV['SKIMA_EDITOR'].to_s.strip
        editor  = nil if editor.empty?
        if command.nil? || editor.nil?
          msg << "##\n"
          msg << "## Step 1/3: Set both $SKIMA_COMMAND and $SKIMA_EDITOR at first.\n"
          if command.nil?
            msg << "##\n"
            msg << "## Example ($SKIMA_COMMAND):\n"
            msg << "##   $ export SKIMA_COMMAND='psql -1 -q -U user1 dbname1'   # for PostgreSQL\n"
          end
          if editor.nil?
            msg << "##\n"
            msg << "## Example ($SKIMA_EDITOR):\n"
            msg << "##   $ export SKIMA_EDITOR='vi'                   # for vi\n"
            msg << "##   $ export SKIMA_EDITOR='emacsclient'          # for emacs\n"
            msg << "##   $ export SKIMA_EDITOR='open -a TextMate'     # for MacOSX\n"
          end
          msg << "##\n"
          msg << "## (Run '#{script} navi' again after above settings.)\n"
          msg << "##\n"
        #
        elsif ! repo.init?
          msg << "##\n"
          msg << "## Step 2/3: Run '#{script} init' to create files and a table.\n"
          msg << "## (You can call it many times; it doesn't remove existing file nor table.)\n"
          msg << "##\n"
          msg << "## Example:\n"
          msg << "##   $ #{script} init      # create directories and files (= '#{File.dirname(repo.history_filepath)}/*'),\n"
          msg << "##                         # and create '#{Repository::HISTORY_TABLE}' table in DB.\n"
          msg << "##\n"
          msg << "## (Run '#{script} navi' again after above command.)\n"
          msg << "##\n"
        #
        else
          msg << "##\n"
          msg << "## Step 3/3: Now you can create a new migration and apply it to DB.\n"
          msg << "##\n"
          msg << "## Example:\n"
          msg << "##   $ #{script} help\n"
          msg << "##   $ #{script} new -m \"create 'foobar' table\"   # create a migration\n"
          msg << "##   $ #{script} hist      # not applied yet.\n"
          msg << "##   $ #{script} up        # apply a migration (= change DB schema)\n"
          msg << "##   $ #{script} hist      # applied successfully!\n"
          msg << "##\n"
          msg << "## Try '#{script} help [command]' for details of each command.\n"
          msg << "##\n"
          msg << "## Good luck!\n"
          msg << "##\n"
        end
        #
        return msg
      end

    end


    class HelpAction < Action
      NAME = "help"
      DESC = "show help message of action, or list action names"
      OPTS = []
      ARGS = '[action]'

      def run(options, args)
        if args.length >= 2
          raise cmdopterr("help: too much argument")
        elsif args.length == 1
          action_name = args[0]
          action_class = Action.find_by_name(action_name)  or
            raise cmdopterr("#{action_name}: unknown action.")
          puts action_class.new.usage()
        else
          usage = Skima::Application.new.usage()
          puts usage
        end
        nil
      end

      private

      def _should_check?
        false
      end

    end


    class InitAction < Action
      NAME = "init"
      DESC = "create necessary files and a table"
      OPTS = []
      ARGS = nil

      def run(options, args)
        repository().init()
      end

      private

      def _should_check?
        false
      end

    end


    class HistAction < Action
      NAME = "hist"
      DESC = "list history of versions"
      OPTS = []
      ARGS = nil

      def run(options, args)
        mig_hist, mig_dict = repository().get_migrations()
        str = '(not_applied_yet)  '
        mig_hist.each do |mig|
          puts "#{mig.version}  #{mig.applied_at_or(str)}  \# [#{mig.author}] #{mig.desc}"
        end
        if ! mig_dict.empty?
          puts "## Applied to DB but not exist in history file:"
          mig_dict.each do |mig|
            puts "#{mig.version}  #{mig.applied_at_or(str)}  \# [#{mig.author}] #{mig.desc}"
          end
        end
      end

    end


    class NewAction < Action
      NAME = "new"
      DESC = "create new migration file and open it by $SKIMA_EDITOR"
      OPTS = [
        "-m text  : description message (mandatory)",
        "-u user  : author name (default: current user)",
        "-p       : plain skeleton",
        "-e editor: editr command (such as 'emacsclient', 'open', ...)",
      ]
      ARGS = nil

      def run(options, args)
        editor = options['e'] || ENV['SKIMA_EDITOR']
        if ! editor || editor.empty?
          _recommend_to_set_SKIMA_EDITOR('create')
          raise cmdopterr("#{NAME}: failed to create migration file.")
        end
        desc = options['m']  or
          raise cmdopterr("#{NAME}: '-m text' option required.")
        author = options['u']
        plain_p = !! options['p']
        #
        mig = repository().create_migration(desc, author, :plain=>plain_p)
        puts "## New migration file:"
        puts mig.filepath
        puts "$ #{editor} #{mig.filepath}"
        system("#{editor} #{mig.filepath}")
      end

    end


    class EditAction < Action
      NAME = "edit"
      DESC = "open migration file by $SKIMA_EDITOR"
      OPTS = [
        "-r        :  edit N-th file from latest version",
        "-e editor : editr command (such as 'emacsclient', 'open', ...)",
      ]
      ARGS = "[version]"

      def run(options, args)
        editor = options['e'] || ENV['SKIMA_EDITOR']
        if ! editor || editor.empty?
          _recommend_to_set_SKIMA_EDITOR('edit')
          raise cmdopterr("#{NAME}: failed to create migration file.")
        end
        version = num = nil
        if options['r']
          options['r'] =~ /\A\d+\z/  or
            raise cmdopterr("#{NAME} -r #{options['r']}: integer expected.")
          num = options['r'].to_i
        else
          if args.length == 0
            #raise cmdopterr("#{NAME}: '-r N' option or version required.")
            num = 1
          elsif args.length > 1
            raise cmdopterr("#{NAME}: too much arguments.")
          elsif args.length == 1
            version = args.first
          else
            raise "** unreachable"
          end
        end
        #
        repo = repository()
        if num
          migs = repo.migrations_in_history_file()
          mig = migs[-num]  or
            raise cmdopterr("#{NAME} -n #{num}: migration file not found.")
        else
          mig = repo.load_migration(version)  or
            raise cmdopterr("#{NAME}: #{version}: version not found.")
        end
        puts "# #{editor} #{repo.migration_filepath(mig.version)}"
        system("#{editor} #{repo.migration_filepath(mig.version)}")
      end

    end


    class StatusAction < Action
      NAME = "status"
      DESC = "show status"
      OPTS = ["-n N :  show N histories (default: 5)"]
      ARGS = nil

      def run(options, args)
        if options['n']
          options['n'] =~ /\A\d+\z/  or
            raise cmdopterr("#{NAME} -n #{options['n']}: integer expected.")
          n = options['n'].to_i
        else
          n = 5
        end
        #
        ret = repository().inspection(n)
        puts "## Status: #{ret[:status]}"
        str = '(not_applied_yet)  '
        if ret[:recent]
          puts "## Recent history:"
          ret[:recent].each do |mig|
            puts "#{mig.version}  #{mig.applied_at_or(str)}  \# [#{mig.author}] #{mig.desc}"
          end
        end
        if ret[:missing]
          puts "## === Applied to DB, but migration file not found ==="
          ret[:missing].each do |mig|
            puts "#{mig.version}  #{mig.applied_at_or(str)}  \# [#{mig.author}] #{mig.desc}"
          end
        end
      end

    end


    class UpAction < Action
      NAME = "up"
      DESC = "apply a next migration"
      OPTS = [
        "-n N : apply N migrations",
        "-a   : apply all migrations",
      ]
      ARGS = nil

      def run(options, args)
        if options['n']
          options['n'] =~ /\A\d+\z/  or
            raise cmdopterr("#{NAME} -n #{options['n']}: integer expected.")
          n = options['n'].to_i
        elsif options['a']
          n = nil
        else
          n = 1
        end
        #
        repository().upgrade(n)
      end

    end


    class DownAction < Action
      NAME = "down"
      DESC = "unapply current migration"
      OPTS = [
        "-n N  : unapply N migrations",
        "--ALL : unapply all migrations",
      ]
      ARGS = nil

      def run(options, args)
        n = 1
        if options['n']
          options['n'] =~ /\A\d+\z/  or
            raise cmdopterr("#{NAME} -n #{options['n']}: integer expected.")
          n = options['n'].to_i
        elsif options['ALL']
          n = nil
        end
        #
        repository().downgrade(n)
      end

    end


    module VersionsHelper   # :nodoc:

      private

      def _versions2migrations(versions, repo, name, should_applied)
        mig_hist, _ = repo.get_migrations()
        mig_dict = {}
        mig_hist.each {|mig| mig_dict[mig.version] = mig }
        ver_chk = {}
        versions.each do |ver|
          repo.load_migration(ver)  or
            raise cmdopterr("#{name}: #{ver}: migration file not found.")
          mig = mig_dict[ver]  or
            raise cmdopterr("#{name}: #{ver}: no such version in history file.")
          if should_applied
            mig.applied_at  or
              raise cmdopterr("#{name}: #{ver}: not applied yet.")
          else
            mig.applied_at.nil?  or
              raise cmdopterr("#{name}: #{ver}: already applied.")
          end
          ver_chk[ver].nil?  or
            raise cmdopterr("#{name}: #{ver}: specified two or more times.")
          ver_chk[ver] = true
        end
        migrations = versions.collect {|ver| mig_dict[ver] }
        return migrations
      end

    end


    class RedoAction < Action
      NAME = "redo"
      DESC = "do migration down, and up it again"
      OPTS = [
        "-n N  : redo N migrations",
        "--ALL : redo all migrations",
      ]
      ARGS = nil

      def run(options, args)
        n = 1
        if options['n']
          options['n'] =~ /\A\d+\z/  or
            raise cmdopterr("#{NAME} -n #{options['n']}: integer expected.")
          n = options['n'].to_i
        elsif options['ALL']
          n = nil
        end
        #
        repo = repository()
        repo.downgrade(n)
        repo.upgrade(n)
      end

    end


    class ApplyAction < Action
      NAME = "apply"
      DESC = "apply specified migrations"
      OPTS = []
      ARGS = "version ..."

      include VersionsHelper

      def run(options, args)
        ! args.empty?  or
          raise cmdopterr("#{NAME}: version required.")
        #
        repo = repository()
        migrations = _versions2migrations(args, repo, NAME, false)
        repo.apply_migrations(migrations)
      end

    end


    class UnapplyAction < Action
      NAME = "unapply"
      DESC = "unapply specified migrations"
      OPTS = []
      ARGS = "version ..."

      include VersionsHelper

      def run(options, args)
        ! args.empty?  or
          raise cmdopterr("#{NAME}: version required.")
        #
        repo = repository()
        migrations = _versions2migrations(args, repo, NAME, true)
        repo.unapply_migrations(migrations)
      end

    end


  end


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
      #;
      action_name = args.shift || default_action_name()
      action_class = Actions::Action.find_by_name(action_name)  or
        raise Util::CommandOptionError.new("#{action_name}: unknown action.")
      action_obj = action_class.new
      action_opts = action_obj.parse(args)
      action_obj.run(action_opts, args)
      #; [!saisg] returns 0 as status code when succeeded.
      return 0
    end

    def usage(parser=nil)
      parser ||= new_cmdopt_parser()
      script = File.basename($0)
      s = ""
      s << "#{script} -- database schema version management tool\n"
      s << "\n"
      s << "Usage: #{script} [global-options] [action [options] [...]]\n"
      s << parser.usage(20, '  ')
      s << "\n"
      s << "Actions:  (default: #{default_action_name()})\n"
      Skima::Actions::Action.subclasses.each do |action_class|
        s << action_class.new.short_usage()
      end
      s << "\n"
      s << "Setup:\n"
      if RUBY_PLATFORM =~ /mswin(?!ce)|mingw|bccwin/
        s << "  C:\\> set SKIMA_COMMAND='psql -q -U user1 database1'   # for PostgreSQL\n"
        s << "  C:\\> export SKIMA_EDITOR='notepad.exe'                # editor command\n"
        s << "  C:\\> ruby skima.rb init\n"
      else
        s << "  $ export SKIMA_COMMAND='psql -q -U user1 database1'   # for PostgreSQL\n"
        s << "  $ export SKIMA_EDITOR='emacsclient'                   # or 'vi', 'open', etc\n"
        s << "  $ skima.rb init\n"
      end
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
        $stderr << "ERROR[#{script}] #{ex.message}\n"
        status = 1
      #;
      rescue SkimaError => ex
        script = File.basename($0)
        $stderr << "ERROR[#{script}] #{ex}\n"
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

    def default_action_name
      return Repository.new.history_file_empty? ? 'navi' : 'status'
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
        when /\A *--(\w[-\w]*)(?:\[=(.+?)\]|=(\S.*?))?(?:\s+\#(\w+))?\s*:(?:\s+(.*)?)?\z/
          short, long, arg, name, desc = nil, $1, ($2 || $3), $4, $5
          arg_required = $2 ? nil : $3 ? true : false
        when /\A *-(\w),\s*--(\w[-\w]*)(?:\[=(.+?)\]|=(\S.*?))?(?:\s+\#(\w+))?\s*:(?:\s+(.*)?)?\z/
          short, long, arg, name, desc = $1, $2, ($3 || $4), $5, $6
          arg_required = $3 ? nil : $4 ? true : false
        when /\A *-(\w)(?:\[(.+?)\]|\s+([^\#\s].*?))?(?:\s+\#(\w+))?\s*:(?:\s+(.*)?)?\z/
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

      def initialize(prefix=nil)
        @prefix = prefix
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
              raise cmdopterr("#{optstr}: invalid option format.")
            #; [!sj0cv] raises error when unknown long option.
            long, argval = $1, $2
            optdef = @optdefs.find {|x| x.long == long }  or
              raise cmdopterr("#{optstr}: unknown option.")
            #; [!a7qxw] raises error when argument required but not provided.
            if optdef.arg_required == true && argval.nil?
              raise cmdopterr("#{optstr}: argument required.")
            #; [!8eu9s] raises error when option takes no argument but provided.
            elsif optdef.arg_required == false && argval
              raise cmdopterr("#{optstr}: unexpected argument.")
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
                raise cmdopterr("-#{ch}: unknown option.")
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
                    raise cmdopterr("-#{ch}: argument required.")
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

      private

      def cmdopterr(message)
        message = "#{@prefix} #{message}" if @prefix
        return CommandOptionError.new(message)
      end

    end#class


    module Expander

      class UnknownVariableError < StandardError
      end

      module_function

      def expand_vars(vars)
        dict = {}
        vars.each do |d|
          d.each do |k, v|
            dict[k] = expand_value(v, dict)
          end
        end
        return dict
      end

      def expand_value(value, dict)
        case value
        when String
          return expand_str(value, dict)
        when Array
          arr = value
          i = 0
          while i < arr.length
            arr[i] = expand_value(arr[i], dict)
          end
          return arr
        when Hash
          hash = value
          hash.keys.each do |k|
            hash[k] = expand_value(hash[k], dict)
          end
          return hash
        else
          return value
        end
      end

      def expand_str(str, dict)
        raise unless dict.is_a?(Hash)
        if str =~ /\A\$\{(.*?)\}\z/
          var = $1
          if var.empty?
            return ''
          elsif dict.key?(var)
            return dict[var]
          else
            raise UnknownVariableError.new("${#{var}}: no such variable.")
          end
        else
          return str.gsub(/\$\{(.*?)\}/) {
            var = $1
            if var.empty?
              ''
            elsif dict.key?(var)
              dict[var].to_s
            else
              raise UnknownVariableError.new("${#{var}}: no such variable.")
            end
          }
        end
      end

    end


  end


end


if __FILE__ == $0
  status = Skima::Application.main()
  exit(status)
end
