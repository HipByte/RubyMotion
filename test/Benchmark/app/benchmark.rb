sleep(1)
puts "# Benchmark Start"

begin
  puts "RubyMotion #{RUBYMOTION_VERSION}"
rescue
  # for CRuby
  puts "Ruby #{RUBY_VERSION}"
  require 'benchmark'

  Dir.glob("app/benchmark/**/*.rb").each do |file|
    load file
  end
end

puts "*** Array ***"
autorelease_pool { bm_array }

puts "*** Hash ***"
autorelease_pool { bm_hash }

puts "*** String ***"
autorelease_pool { bm_string }

puts "*** Time ***"
autorelease_pool { bm_time }

exit(0)
