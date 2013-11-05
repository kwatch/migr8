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
