Migr8.rb
========

Migr8.rb is a database schema version management tool.

* Easy to install, easy to setup, and easy to start
* No configuration file; instead, only two environment variables
* Designed carefully to suit Git or Mercurial
* Supports SQLite3, PostgreSQL, and MySQL
* Written in Ruby (>= 1.8)


Quick Start
-----------

1. Donwload migr8.rb.

        $ curl -Lo migr8.rb http://bit.ly/migr8_rb
        $ chmod a+x migr8.rb

2. Set environment variables: $MIGR8_COMMAND and $MIGR8_EDITOR.

        $ export MIGR8_COMMAND="sqlite3 dbfile1"            # for SQLite3
        $ export MIGR8_COMMAND="psql -q -U user1 dbname1"   # for PostgreSQL
        $ export MIGR8_COMMAND="mysql -s -u user1 dbname1"  # for MySQL

        $ export MIGR8_EDITOR="open -a TextMate"     # for TextMate (MacOSX)
        $ export MIGR8_EDITOR="emacsclient"          # for Emacs
        $ export MIGR8_EDITOR="vim"                  # for Vim

3. Create managiment files and table.

        $ ./migr8.rb init         # create files in current directory,
                                  # and create a table in DB.

4. Now you can manage DB schema versions.

        $ ./migr8.rb                                 # show current status
        $ ./migr8.rb new -m "create 'users' table"   # create a migration
               # or  ./migr8.rb new --table=users
        $ ./migr8.rb                                 # show status again
        $ ./migr8.rb up                              # apply migration
        $ ./migr8.rb                                 # show status again
        $ ./migr8.rb hist                            # list history

5. You may got confliction error when `git rebase` or `git pull`.
   In this case, you must resolve it by hand.
   (This is intended design.)

        $ git rebase master         # confliction!
        $ ./migr8.rb hist -o        # open 'migr8/history.txt', and
                                    # resolve confliction manually
        $ ./migr8.rb hist           # check whether history file is valid
        $ git add migr8/history.txt
        $ git rebase --continue


Tips
----

* `migr8.rb up -a` applys all migrations, while `migr8.rb up` applys a
  migration.

* `migr8.rb -D up` saves SQL executed into `migr8/history.txt` file.

* `migr8.rb redo` is equivarent to `migr8.rb down; migr8.rb up`.

* `migr8.rb new -p` generates migration file with plain skeleton, and
  `migr8.rb new --table=name` generates with table name.

* `migr8.rb unapply -x` unapplies migration which is applied in DB but
  corresponding migration file doesn't exist.
  (Describing in detail, `migr8.rb unapply -x abcd1234` runs `down` script
  in `_migr_history` table, while `migr8.rb unapply abcd1234` runs `down`
  script in `migr8/migrations/abcd1234.yaml` file.)
  This may help you when switching Git/Hg branch.

* **MySQL doesn't support transactional DDL**.
  It will cause troubles when you have errors in migration script
  (See https://www.google.com/search?q=transactional+DDL for details).
  On the other hand, SQLite3 and PostgreSQL support transactional DDL,
  and DDL will be rollbacked when error occurred in migration script.
  Very good.


<!--

Trouble Shooting
----------------

* Command `migr8.rb unapply -x` unapplies migration which is applied in DB
  but it's migration file doesn't exist in 'migr8/migrations' directory.
  You may face this case when switching Git branch.

  There can be migrations which are applied in DB but migration file does
  not exit in 'migr8/migrations' directory. You my face this case when
  switching Git/Hg branch.

  For example, the following shows that migration 'uhtu4853' is applied
  in DB, but file 'migr8/migrations/uhtu4853.yaml' does not exist.

        $ ./migr8.rb
        ## Status: all applied
        ## Recent history:
        ssgc3376  2013-11-18 10:04:40  # [kwatch] create 'groups' table
        ## !!! The following migrations are applied to DB, but files are not found.
        ## !!! (Try `migr8.rb unapply -x abcd1234` to unapply them.)
        uhtu4853  2013-11-18 10:04:46  # [kwatch] create 'users' table

  You may try to unapply 'uhtu4853', but will be refused because migration
  file does not exist.

        $ ./migr8.rb unapply uhtu4853
        ERROR[migr8.rb] unapply: uhtu4853: no such version in history file.

  In this case, `migr8.rb new -x` is the answer.

        $ ./migr8.rb unapply -x uhtu4853
        ## unapplying uhtu4853  # [kwatch] create 'users' table
        $ ./migr8.rb
        ## Status: all applied
        ## Recent history:
        ssgc3376  2013-11-20 10:04:46  # [kwatch] create 'groups' table

-->


Usage and Actions
-----------------

    Usage: migr8.rb [global-options] [action [options] [...]]
      -h, --help          : show help
      -v, --version       : show version
      -D, --debug         : not remove sql file ('migr8/tmp.sql') for debug

    Actions:  (default: status)
      readme              : !!READ ME AT FIRST!!
      help [action]       : show help message of action, or list action names
      init                : create necessary files and a table
      hist                : list history of versions
        -o                :   open history file with $MIGR8_EDITOR
        -b                :   rebuild history file from migration files
      new                 : create new migration file and open it by $MIGR8_EDITOR
        -m text           :   description message (mandatory)
        -u user           :   author name (default: current user)
        -p                :   plain skeleton
        -e editor         :   editr command (such as 'emacsclient', 'open', ...)
        --table=table     :   skeleton to create table
        --column=tbl.col  :   skeleton to add column
        --index=tbl.col   :   skeleton to create index
        --unique=tbl.col  :   skeleton to add unique constraint
      edit [version]      : open migration file by $MIGR8_EDITOR
        -r N              :   edit N-th file from latest version
        -e editor         :   editr command (such as 'emacsclient', 'open', ...)
      status              : show status
      up                  : apply next migration
        -n N              :   apply N migrations
        -a                :   apply all migrations
      down                : unapply current migration
        -n N              :   unapply N migrations
        --ALL             :   unapply all migrations
      redo                : do migration down, and up it again
        -n N              :   redo N migrations
        --ALL             :   redo all migrations
      apply version ...   : apply specified migrations
      unapply version ... : unapply specified migrations
        -x                :   unapply versions with down-script in DB, not in file


TODO
----

* [_] write more tests
* [_] test on windows
* [_] create RubyGems package
* [_] support eRuby templating
* [_] implement in Python
* [_] implement in JavaScript


Changes
-------

### Release 0.3.0 (2013-11-22) ###

* [enhance] Add `-x` option to `unapply` action which unapplies migrations
  by down-script in DB, not in migration file.
  You can unapply migrations which files are missing in some reason.
* [change] Eliminate indentation from output of 'readme' action.


### Release 0.2.1 (2013-11-20) ###

* [bugfix] Fix `new --table=name` action to set table name correctly


### Release 0.2.0 (2013-11-14) ###

* [enhance] Add new options to `new` action for some skeletons
  * `new --table=table` : create table
  * `new --column=tbl.col` : add column to table
  * `new --index=tbl.col` : create index on column
  * `new --unique=tbl.col` : add unique constraint on column
* [enhance] Add new option `hist -b` action which re-generate history file.
* [change] Change several error messages
* [change] Tweak SQL generated on SQLite3


### Release 0.1.1 (2013-11-12) ###

* [IMPORTANT] Change history table schema: SORRY, YOU MUST RE-CREATE HISTORY TABLE.
* [enhance] Fix 'up' action to save both up and down script into history table.


### Release 0.1.0 (2013-11-11) ###

* Public release


License
-------

$License: MIT-License $


Copyright
---------

$Copyright: copyright(c) 2013 kuwata-lab.com all rights reserved. $
