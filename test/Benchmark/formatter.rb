#!/usr/bin/env ruby

data = STDIN.read
data.each_line do |line|
  if line =~ /^(.+)\s+\(([\d\.]+)\)$/
    puts "\"#{$1.strip}\",#{$2}"
  end
end