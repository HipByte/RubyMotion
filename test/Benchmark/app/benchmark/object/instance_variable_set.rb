def object_instance_variable_set(x)
  user = User.new
  x.report "instance_variable_set" do
    1000000.times do
      user.instance_variable_set(:@age, 42)
    end
  end

end
