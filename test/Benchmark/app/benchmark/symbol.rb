def bm_symbol
  Benchmark.benchmark("", 30, "%r\n") do |x|
    symbol_to_s(x)
  end
end
