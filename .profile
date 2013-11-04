if [ -n "$RUBYLIB" ]; then
  export RUBYLIB=$RUBYLIB:$PWD/lib
else
  export RUBYLIB=$PWD/lib
fi

export SKEEMA_EDITOR='open -a Emacs'
#export SKEEMA_COMMAND='psql -q -U user1 example1'
export SKEEMA_COMMAND='psql -U user1 example1'
