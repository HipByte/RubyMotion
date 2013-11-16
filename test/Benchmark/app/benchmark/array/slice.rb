def array_slice(x)
  large_array = $large_array.dup
  x.report "slice index" do
    10000.times do |i|
      large_array.slice(5)
    end
  end

  x.report "slice start, length" do
    10000.times do |i|
      large_array.slice(5, 5)
    end
  end

  x.report "slice range" do
    10000.times do |i|
      large_array.slice(5..10)
    end
  end

  x.report "slice! index" do
    10000.times do |i|
      large_array2 = $large_array.dup
      large_array2.slice!(5)
    end
  end

  x.report "slice! start, length" do
    10000.times do |i|
      large_array2 = $large_array.dup
      large_array2.slice!(5, 5)
    end
  end

  x.report "slice! range" do
    10000.times do |i|
      large_array2 = $large_array.dup
      large_array2.slice!(5..10)
    end
  end
end
