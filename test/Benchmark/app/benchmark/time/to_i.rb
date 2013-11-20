def time_to_i(x)
  x.report "to_i" do
    time = Time.now
    100000.times do
      time.to_i
    end
  end
end
