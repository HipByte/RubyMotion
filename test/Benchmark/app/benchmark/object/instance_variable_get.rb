def object_instance_variable_get(x)
  user = User.new
  x.report "instance_variable_get" do
    1000000.times do
      user.instance_variable_get(:@name)
    end
  end

end
