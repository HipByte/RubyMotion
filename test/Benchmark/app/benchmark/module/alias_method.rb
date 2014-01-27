def module_alias_method(x)
  x.report "alias_method" do
    10000.times do |i|
      Foo.class_eval {
        alias_method(:"test#{i}", :to_s)
      }
    end
  end
end
