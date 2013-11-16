def array_map(x)
  ary = (0..100).to_a
  x.report "map" do
    10000.times do |i|
      ary.map { |item| 1 }
    end
  end

  x.report "map!" do
    10000.times do |i|
      ary.dup.map! { |item| 1 }
    end
  end
end
