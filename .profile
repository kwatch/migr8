if [ -n "$RUBYLIB" ]; then
  export RUBYLIB=$RUBYLIB:$PWD/lib
else
  export RUBYLIB=$PWD/lib
fi

export SKIMA_EDITOR='open -a Emacs'
#export SKIMA_COMMAND='psql -q -U user1 example1'
export SKIMA_COMMAND='psql -U user1 example1'
