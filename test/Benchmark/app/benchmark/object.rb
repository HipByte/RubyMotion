class User
  def initialize
    @name = "foo"
    @age  = 20
  end
end

def bm_object
  Benchmark.benchmark("", 30, "%r\n") do |x|
    object_instance_eval(x)
    object_instance_of(x)
    object_instance_variable_get(x)
    object_instance_variable_set(x)
    object_is_a(x)
    object_respond_to(x)
    object_send(x)
  end
end
