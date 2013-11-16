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
bm_array

puts "*** Hash ***"
bm_hash

exit(0)