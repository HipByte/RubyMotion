def time_strftime(x)
  x.report "strftime" do
    time = Time.now
    100000.times do
      time.strftime('%m/%d/%Y')
    end
  end
end
