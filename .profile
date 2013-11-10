if [ -n "$RUBYLIB" ]; then
  export RUBYLIB=$RUBYLIB:$PWD/lib
else
  export RUBYLIB=$PWD/lib
fi

export MIGR8_EDITOR='open -a Emacs'
export MIGR8_COMMAND='psql -q -U user1 example1'
#export MIGR8_COMMAND='psql -U user1 example1'
