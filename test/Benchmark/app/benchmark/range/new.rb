def range_new(x)
  x.report "0..10" do
    500000.times do |i|
      0..10
    end
  end

  x.report "new(0,10)" do
    500000.times do |i|
      Range.new(0, 10)
    end
  end

  x.report "0...10" do
    500000.times do |i|
      0...10
    end
  end

  x.report "new(0,10,true)" do
    500000.times do |i|
      Range.new(0, 10, true)
    end
  end

  x.report "0xffff..0xfffff" do
    500000.times do |i|
      0xffff..0xfffff
    end
  end

  x.report "0.5..2.4" do
    500000.times do |i|
      0.5..2.4
    end
  end

  x.report "'a'..'z'" do
    500000.times do |i|
      'a'..'z'
    end
  end
end
