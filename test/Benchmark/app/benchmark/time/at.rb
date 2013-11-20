def time_at(x)
  x.report "at with small number" do
    100000.times do |i|
      Time.at(i)
    end
  end

  x.report "at with large number" do
    100000.times do |i|
      Time.at(1000000 * i)
    end
  end
end
