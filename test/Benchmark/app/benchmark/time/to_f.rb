def time_to_f(x)
  x.report "to_f" do
    time = Time.now
    100000.times do
      time.to_f
    end
  end
end
