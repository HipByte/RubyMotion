def module_class_eval(x)
  x.report "class_eval" do
    1000000.times do
      Object.class_eval {}
    end
  end

end
