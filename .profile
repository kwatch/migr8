if [ -n "$RUBYLIB" ]; then
  export RUBYLIB=$RUBYLIB:$PWD/lib
else
  export RUBYLIB=$PWD/lib
fi
