
case :$PATH: in
  *:$PWD/lib:*)
    ;;
  *)
    export PATH=$PATH:$PWD/lib
esac

if [ -n "$RUBYLIB" ]; then
  export RUBYLIB=$RUBYLIB:$PWD/lib
else
  export RUBYLIB=$PWD/lib
fi

export GEM_HOME=$PWD/local/gems

export MIGR8_COMMAND='psql -q -U user1 example1'
#export MIGR8_COMMAND='psql -U user1 example1'
#export MIGR8_COMMAND='sqlite3 example1.db'
#export MIGR8_COMMAND='mysql -s -u user1 example1'

export MIGR8_EDITOR='open -a Emacs'
