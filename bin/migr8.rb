#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

###
### $Release: 0.4.0 $
### $Copyright: copyright(c) 2013 kuwata-lab.com all rights reserved $
### $License: MIT License $
###

require 'migr8'

#if __FILE__ == $0
  status = Migr8::Application.main()
  exit(status)
#end
