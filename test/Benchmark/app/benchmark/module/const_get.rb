def module_const_get(x)
  x.report "const_get" do
    1000000.times do
      Foo.const_get(:CONST_FOO)
    end
  end

  x.report "const_get (included)" do
    1000000.times do
      Bar.const_get(:CONST_BAZ)
    end
  end

end
