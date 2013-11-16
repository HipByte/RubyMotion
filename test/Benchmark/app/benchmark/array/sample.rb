def array_sample(x)
  large_array = $large_array.dup

  x.report "sample(10)" do
    1000.times do
      large_array.sample(10)
    end
  end

  x.report "sample(array.size)" do
    1000.times do
      large_array.sample(large_array.size)
    end
  end
end