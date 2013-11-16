$large_array = (1..1000).to_a

def bm_array
  Benchmark.benchmark("", 30, "%r\n") do |x|
    array_at(x)
    array_concat(x)
    array_dup(x)
    array_each(x)
    array_flatten(x)
    array_map(x)
    array_reject(x)
    array_reverse(x)
    array_rotate(x)
    array_sample(x)
    array_select(x)
    array_slice(x)
    array_sort(x)
    array_uniq(x)
  end
end
