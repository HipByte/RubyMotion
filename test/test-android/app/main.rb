$running = false
$specs = []
$describe = nil
$befores = []
$afters = []
$specs_total = 0
$specs_exceptions = 0
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
      puts "Expectation failed (expected `#{@obj}' (#{@obj.class}) == `#{x}' (#{x.class}))"
      $expectations_failures += 1
    end
    $expectations_total += 1
  end
end

class ScratchPadClass < Java::Lang::Object
  def record(obj); @obj = obj; end
  def <<(x); @obj << x; end
  def recorded; @obj; end
  def clear; @obj = nil; end
end

ScratchPad = ScratchPadClass.new

class Object
  def describe(msg, &block)
    if $running
      old_describe = $describe
      $describe = "#{$describe} #{msg}"
      block.call
      $describe = old_describe
    else
      $specs << [msg, block]
    end
  end
 
  def before(step, &block)
    # Assume :each
    $befores << block
  end

  def after(step, &block)
    # Assume :each
    $afters << block
  end

  def it(msg)
    spec = "#{$describe} #{msg}"
    puts spec
    $befores.each { |x| x.call }
    begin
      yield
    rescue => exc
      puts "ERROR: Exception happened: #{exc}"
      $specs_exceptions += 1
    end
    $specs_total += 1
    $afters.each { |x| x.call }
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

  def be_an_instance_of(klass)
    lambda do |obj, res|
      if obj.instance_of?(klass) != res
        puts "Expectation failed (expected `#{obj}' to be instance_of? `#{klass}')"
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

  def be_nil
    lambda do |obj, res|
      if (obj == nil) != res
        puts "Expectation failed (expected `#{obj}' to be nil')"
        $expectations_failures += 1
      end
      $expectations_total += 1
    end
  end

  def be_true
    lambda do |obj, res|
      if (obj == true) != res
        puts "Expectation failed (expected `#{obj}' to be true')"
        $expectations_failures += 1
      end
      $expectations_total += 1
    end
  end

  def be_false
    lambda do |obj, res|
      if (obj == false) != res
        puts "Expectation failed (expected `#{obj}' to be false')"
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
    $running = true
    $specs.each do |ary|
      $befores.clear
      $afters.clear
      $describe = ary[0]
      ary[1].call
    end
    puts "Spec suite finished: #{$specs_total} specs, #{$specs_exceptions} exception(s), #{$expectations_total} expectations, #{$expectations_failures} failure(s)"
  end
end
