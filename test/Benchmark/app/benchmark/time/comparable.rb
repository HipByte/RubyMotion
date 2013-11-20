def time_comparable(x)
  time1 = Time.at(10000)
  time2 = Time.at(10001)

  x.report "<" do
    100000.times do
      time1 < time2
    end
  end

  x.report ">" do
    100000.times do
      time1 > time2
    end
  end

  x.report "==" do
    100000.times do
      time1 == time2
    end
  end
end
