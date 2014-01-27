def object_respond_to(x)
  obj = Object.new
  x.report "respond_to" do
    2000000.times do
      obj.respond_to?(:nil?)
    end
  end
end
