Skima.rb
========

Skima.rb is a database schema version management tool.

* Easy to install, easy to setup, and easy to start
* No configuration file; instead, only two environment variables
* Designed carefully to suit Git or Mercurial
* Supports SQLite3, PostgreSQL, and MySQL
* Written in Ruby (>= 1.8)


Quick Start
-----------

1. Donwload skima.rb.

        $ curl -Lo skima.rb http://bit.ly/skima_rb
        $ chmod a+x skima.rb

2. Set environment variables: $SKIMA_COMMAND and $SKIMA_EDITOR.

        $ export SKIMA_COMMAND="sqlite3 dbfile1"            # for SQLite3
        $ export SKIMA_COMMAND="psql -q -U user1 dbname1"   # for PostgreSQL
        $ export SKIMA_COMMAND="mysql -s -u user1 dbname1"  # for MySQL

        $ export SKIMA_EDITOR="open -a TextMate"     # for TextMate (MacOSX)
        $ export SKIMA_EDITOR="emacsclient"          # for Emacs
        $ export SKIMA_EDITOR="vim"                  # for Vim

3. Create files and a table.

        $ ./skima.rb init         # create files in current directory,
                                  # and create a table in DB.

4. Now you can manage DB schema versions.

        $ ./skima.rb                                  # show current status
        $ ./skima.rb new -m "create 'users' table"    # create a migration
        $ ./skima.rb                                  # show status again
        $ ./skima.rb up                               # apply migration
        $ ./skima.rb                                  # show status again
        $ ./skima.rb hist                             # list history

5. You may got confliction error when `git rebase` or `git pull`.
   In this case, you must resolve it by hand.
   (This is intended design.)

        $ git rebase master     # confliction!
        $ ./skima.rb hist -o    # open 'skima/history.txt' and resolve confliction
        $ ./skima.rb hist       # check whether history file is valid
        $ git add skima/history.txt
        $ git rebase --continue


Tips
----

* `skima.rb up` applys only a migration, and `skima.rb up -a` applys all migrations.

* `skima.rb redo` is equivarent to `skima.rb down; skima.rb up`.

* `skima.rb new -p` generates migration file with plain skeleton.

* **MySQL doesn't support transactional DDL**.
  It will cause troubles when you have errors in migration script
  (See https://www.google.com/search?q=transactional+DDL for details).
  On the other hand, SQLite3 and PostgreSQL support transactional DDL,
  and DDL will be rollbacked when error occurred in migration script.
  Very good.


Usage and Actions
-----------------

    Usage: skima.rb [global-options] [action [options] [...]]
      -h, --help          : show help
      -v, --version       : show version
      -D, --debug         : not remove sql file ('skima/tmp.sql') for debug

    Actions:  (default: status)
      intro               : !!RUN THIS ACTION AT FIRST!!
      help [action]       : show help message of action, or list action names
      init                : create necessary files and a table
      hist                : list history of versions
        -o                :   open history file with $SKIMA_EDITOR
      new                 : create new migration file and open it by $SKIMA_EDITOR
        -m text           :   description message (mandatory)
        -u user           :   author name (default: current user)
        -p                :   plain skeleton
        -e editor         :   editr command (such as 'emacsclient', 'open', ...)
      edit [version]      : open migration file by $SKIMA_EDITOR
        -r                :   edit N-th file from latest version
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


TODO
----

* [_] write more tests
* [_] test on windows
* [_] skima.rb new --table=table
* [_] skima.rb new --column=tbl(col,col2,..)
* [_] skima.rb new --index=tbl(col,col2,..)
* [_] skima.rb new --unique=tbl(col,col2,..)
* [_] implement in Python
* [_] implement in JavaScript


Changes
-------

### Release 0.1.0 (2013-11-11) ###

* Public release


License
-------

MIT-License


Copyright
---------

Copyright(c) 2013 kuwata-lab.com all rights reserved.
