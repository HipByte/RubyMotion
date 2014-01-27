def object_instance_eval(x)
  obj = Object.new
  x.report "instance_eval" do
    2000000.times do
      obj.instance_eval { }
    end
  end
end
