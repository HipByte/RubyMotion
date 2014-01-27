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

puts "*** Range ***"
autorelease_pool { bm_range }

puts "*** String ***"
autorelease_pool { bm_string }

puts "*** Symbol ***"
autorelease_pool { bm_symbol }

puts "*** Time ***"
autorelease_pool { bm_time }

puts "*** Rational ***"
autorelease_pool { bm_rational }

puts "*** Module ***"
autorelease_pool { bm_module }

puts "*** Object ***"
autorelease_pool { bm_object }

exit(0)
