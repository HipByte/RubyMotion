def array_concat(x)
  ary = []
  x.report "<<" do
    1000000.times do |i|
      ary << i
    end
  end

  ary1 = (1..100).to_a
  ary2 = (1..100).to_a
  x.report "concat" do
    100000.times do |i|
      a = ary1.dup
      a.concat(ary2)
    end
  end
end
