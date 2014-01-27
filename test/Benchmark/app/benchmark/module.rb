module Baz
  CONST_BAZ = "baz"
  @@baz = "baz"
end

class Foo
  CONST_FOO = 42
  @@foo = "foo"
end

class Bar
  include Baz
end

def bm_module
  Benchmark.benchmark("", 30, "%r\n") do |x|
    module_alias_method(x)
    module_class_eval(x)
    module_class_variable_get(x)
    module_class_variable_set(x)
    module_const_get(x)
    module_const_set(x)
  end
end
