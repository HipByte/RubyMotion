def object_is_a(x)
  obj = Object.new
  x.report "is_a? Object" do
    2000000.times do
      obj.is_a?(Object)
    end
  end

  x.report "is_a? Fixnum" do
    2000000.times do
      1.is_a?(Fixnum)
    end
  end

  string = "foo"
  x.report "is_a? String" do
    2000000.times do
      string.is_a?(String)
    end
  end
end
