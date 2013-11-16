def array_sort(x)
  array = $small_fixnum_array.dup
  x.report "sort" do
    10000.times do |i|
      array.sort
    end
  end

  x.report "sort with block" do
    1000.times do |i|
      array.sort {|a, b| b <=> a }
    end
  end

  x.report "sort!" do
    10000.times do |i|
      array = $small_fixnum_array.dup
      array.sort!
    end
  end

  x.report "sort! with block" do
    1000.times do |i|
      array = $small_fixnum_array.dup
      array.sort! {|a, b| b <=> a }
    end
  end
end
