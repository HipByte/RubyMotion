def bm_rational
  Benchmark.benchmark("", 30, "%r\n") do |x|
    rational_new(x)
    rational_plus(x)
    rational_minus(x)
    rational_divide(x)
    rational_multiply(x)
  end
end
