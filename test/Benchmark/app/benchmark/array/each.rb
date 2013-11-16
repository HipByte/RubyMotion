def array_each(x)
  large_array = $large_array.dup

  x.report "each" do
    10000.times do
      large_array.each do |item|
      end
    end
  end

end
