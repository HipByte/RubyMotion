def time_plus(x)
  time1 = Time.at(10000)
  time2 = Time.at(10001)

  x.report "+ fixnum" do
    10000.times do
      time1 + 100
    end
  end

  x.report "+ float" do
    10000.times do
      time1 + 123.45
    end
  end
end
