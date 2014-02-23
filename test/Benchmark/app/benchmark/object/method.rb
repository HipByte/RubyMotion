def object_method(x)
  obj = Object.new
  x.report "method" do
    100000.times do
      obj.method(:to_s)
    end
  end
end
