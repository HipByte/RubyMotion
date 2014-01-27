def object_instance_of(x)
  obj = Object.new
  x.report "instance_of Object" do
    2000000.times do
      obj.instance_of?(Object)
    end
  end

  x.report "instance_of Fixnum" do
    2000000.times do
      1.instance_of?(Fixnum)
    end
  end

  string = "foo"
  x.report "instance_of String" do
    2000000.times do
      string.instance_of?(String)
    end
  end
end
