def array_uniq(x)
  large_array = $large_array.dup

  x.report "uniq" do
    1000.times do
      large_array.uniq
    end
  end

  x.report "uniq!" do
    1000.times do
      large_array = $large_array.dup
      large_array.uniq!
    end
  end
end