def time_now(x)
  x.report "now" do
    100000.times do
      Time.now
    end
  end
end
