def array_select(x)
  large_array = $large_array.dup
  x.report "select all" do
    1000.times do |i|
      large_array.select { |v| true }
    end
  end

  x.report "select none" do
    1000.times do |i|
      large_array.select { |v| false }
    end
  end
end
