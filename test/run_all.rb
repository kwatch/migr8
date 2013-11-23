# -*- coding: utf-8 -*-

here = File.dirname(File.expand_path(__FILE__))
Dir.glob("#{here}/*_test.rb").each do |fpath|
  require fpath
end


