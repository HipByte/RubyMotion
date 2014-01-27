def module_class_variable_get(x)
  x.report "class_variable_get" do
    1000000.times do
      Foo.class_variable_get(:@@foo)
    end
  end

  x.report "class_variable_get (included)" do
    1000000.times do
      Bar.class_variable_get(:@@baz)
    end
  end

end
