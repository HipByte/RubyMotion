$specs = []
$describe = nil
$expectations_total = 0
$expectations_failures = 0

class ShouldResult < Java::Lang::Object
  def set_object(obj)
    @obj = obj
  end

  def set_expectation_result(res)
    @res = res
  end

  def ==(x)
    if (@obj == x) != @res
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
      condition.call(self, true)
    else
      res = ShouldResult.new
      res.set_object self
      res.set_expectation_result true
      res
    end
  end

  def should_not(condition=nil)
    if condition
      condition.call(self, false)
    else
      res = ShouldResult.new
      res.set_object self
      res.set_expectation_result false
      res
    end
  end


  def be_kind_of(klass)
    lambda do |obj, res|
      if obj.kind_of?(klass) != res
        puts "Expectation failed (expected `#{obj}' to be kind_of? `#{klass}')"
        $expectations_failures += 1
      end
      $expectations_total += 1
    end
  end

  def equal(obj2)
    lambda do |obj, res|
      if obj.equal?(obj2) != res
        puts "Expectation failed (expected `#{obj}' to be equal? `#{klass}')"
        $expectations_failures += 1
      end
      $expectations_total += 1
    end
  end

  def respond_to(sel)
    lambda do |obj, res|
      if obj.respond_to?(sel) != res
        puts "Expectation failed (expected `#{obj}' to respond_to? `#{sel}')"
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
