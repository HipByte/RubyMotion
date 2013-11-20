def bm_time
  Benchmark.benchmark("", 30, "%r\n") do |x|
    time_at(x)
    time_comparable(x)
    time_minus(x)
    time_now(x)
    time_plus(x)
    time_strftime(x)
    time_to_f(x)
    time_to_i(x)
  end
end
