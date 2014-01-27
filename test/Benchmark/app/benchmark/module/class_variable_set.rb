def module_class_variable_set(x)
  x.report "class_variable_set" do
    100000.times do |i|
      Foo.class_variable_set(:"@@foo#{i}", 42)
    end
  end

  x.report "class_variable_set (included)" do
    100000.times do |i|
      Bar.class_variable_set(:"@@baz#{i}", 42)
    end
  end

end
