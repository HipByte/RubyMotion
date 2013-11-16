def array_reverse(x)
  large_array = $large_array.dup
  x.report "reverse" do
    10000.times do |i|
      large_array.reverse
    end
  end

  x.report "reverse!" do
    10000.times do |i|
      large_array = $large_array.dup
      large_array.reverse!
    end
  end
end
