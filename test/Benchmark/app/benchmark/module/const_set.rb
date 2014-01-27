def module_const_set(x)
  x.report "const_set" do
    100000.times do |i|
      Foo.const_set(:"CONST_FOO#{i}", 42)
    end
  end

  x.report "const_set (included)" do
    100000.times do |i|
      Bar.const_set(:"CONST_BAZ#{i}", 42)
    end
  end

end
