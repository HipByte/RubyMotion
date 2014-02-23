def object_method_missing(x)
  obj = User.new
  x.report "method_missing" do
    100000.times do
      obj.foobarbaz
    end
  end
end
