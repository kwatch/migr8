# -*- coding: utf-8 -*-


class Dummy

  def stdout
    bkup = $stdout
    $stdout = stdout = StringIO.new
    begin
      yield
    ensure
      $stdout = bkup
    end
    stdout.rewind
    return stdout.read()
  end

  def stderr
    bkup = $stderr
    $stderr = stderr = StringIO.new
    begin
      yield
    ensure
      $stderr = bkup
    end
    stderr.rewind
    return stderr.read()
  end

  def stdouterr
    bkup = [$stdout, $stderr]
    $stdout = stdout = StringIO.new
    $stderr = stderr = StringIO.new
    begin
      yield
    ensure
      $stdout, $stderr = bkup
    end
    stdout.rewind
    stderr.rewind
    return [stdout.read(), stderr.read()]
  end

end


Dummy.class_eval do

  def self.partial_regexp(string, pattern=/\[==(.*)==\]/)
    pat = '\A'
    pos = 0
    string.scan(pattern) do
      m = Regexp.last_match
      text = string[pos...m.begin(0)]
      pos = m.end(0)
      pat << Regexp.escape(text)
      pat << m[1]
    end
    rest = pos == 0 ? string : string[pos..-1]
    pat << Regexp.escape(rest)
    pat << '\z'
    $stderr.puts "\033[0;31m*** debug: pat=\n#{pat}\033[0m"
    return Regexp.compile(pat)
  end

end


if __FILE__ == $0

  text = <<'END'
Usage: skeema.rb [global-options] [action [options] [...]]
  -h, --help          : show help
  -v, --version       : show version

Actions (default: [==(navi|status)==]):
  navi                : !!RUN THIS ACTION AT FIRST!!
  help [action]       : show help message of action, or list action names
  init                : create necessary files and a table
  hist                : list history of versions
  new                 : create new migration file and open it by $SKEEMA_EDITOR
  edit [version]      : open migration file by $SKEEMA_EDITOR
  status              : show status
  up                  : apply a next migration
  down                : unapply current migration
  redo                : do migration down, and up it again
  apply version ...   : apply specified migrations
  unapply version ... : unapply specified migrations
END

  Dummy.pattern_text(text)

end
