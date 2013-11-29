def bm_range
  Benchmark.benchmark("", 30, "%r\n") do |x|
    range_new(x)
  end
end
