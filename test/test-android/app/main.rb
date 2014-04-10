$specs = []
$describe = nil
$expectations_total = 0
$expectations_failures = 0

class ShouldResult < Java::Lang::Object
  def set_object(obj)
    @obj = obj
  end

  def ==(x)
    if !(@obj == x)
      puts "Expectation failed (expected `#{@obj}' == `#{x}')"
      $expectations_failures += 1
    end
    $expectations_total += 1
  end
end

class Object
  def describe(msg, &block)
    $specs << [msg, block]
  end
 
  def it(msg)
    puts "#{$describe} #{msg}"
    yield
  end

  def should(condition=nil)
    if condition
      condition.call(self)
    else
      res = ShouldResult.new
      res.set_object self
      res
    end
  end

  def be_kind_of(klass)
    lambda do |obj|
      if !obj.kind_of?(klass)
        puts "Expectation failed (expected `#{obj}' to be kind_of? `#{klass}')"
        $expectations_failures += 1
      end
      $expectations_total += 1
    end
  end

  def equal(obj2)
    lambda do |obj|
      if !(obj.equal?(obj2))
        puts "Expectation failed (expected `#{obj}' to be equal? `#{klass}')"
        $expectations_failures += 1
      end
      $expectations_total += 1
    end
  end

  def mock(obj)
    # XXX we probably should be smarter here.
    obj
  end
end

class MainActivity < Android::App::Activity
  def onCreate(savedInstanceState)
    super
    $specs.each do |ary|
      $describe = ary[0]
      ary[1].call
    end
    puts "Spec suite finished: #{$expectations_total} expectations, #{$expectations_failures} failure(s)."
  end
end
