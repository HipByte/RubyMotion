def object_send(x)
  obj = Object.new
  x.report "send" do
    2000000.times do
      obj.send(:nil?)
    end
  end
end
