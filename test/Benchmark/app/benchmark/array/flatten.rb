def array_flatten(x)
  flat_array = (0...50).to_a
  nested_array = (0...5).to_a
  3.times do
    nested_array = (0...5).map { nested_array }
  end

  x.report "flatten - flat" do
    1000.times do |i|
      flat_array.flatten
    end
  end

  x.report "flatten! - flat" do
    1000.times do |i|
      flat_array.dup.flatten!
    end
  end

  x.report "flatten - nested" do
    1000.times do |i|
      nested_array.flatten
    end
  end

  x.report "flatten! - nested" do
    1000.times do |i|
      nested_array.dup.flatten!
    end
  end
end
