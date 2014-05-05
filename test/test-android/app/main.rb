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
    __assert__(@obj == x, @res, "Expected `#{@obj}' (of class #{@obj.class}) to be == `#{x}' (of class #{x.class})")
  end
end

class ScratchPadClass < Java::Lang::Object
  def record(obj); @obj = obj; end
  def <<(x); @obj << x; end
  def recorded; @obj; end
  def clear; @obj = nil; end
end

ScratchPad = ScratchPadClass.new

class LanguageSpecsClass < Java::Lang::Object
  def blanks
    " \t"
  end

  def white_spaces
    blanks + "\f\n\r\v"
  end

  def non_alphanum_non_space
    '~!@#$%^&*()+-\|{}[]:";\'<>?,./'
  end
end

LanguageSpecs = LanguageSpecsClass.new

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

  def __assert__(val, res, error_msg)
    if val != res
      puts "*** ERROR: Expectation failed: #{error_msg}"
      $expectations_failures += 1
    end
    $expectations_total += 1
  end

  def be_kind_of(klass)
    lambda do |obj, res|
      __assert__(obj.kind_of?(klass), res, "Expected `#{obj}' to be kind_of? `#{klass}'")
    end
  end

  def be_an_instance_of(klass)
    lambda do |obj, res|
      __assert__(obj.instance_of?(klass), res, "Expected `#{obj}' to be instance_of? `#{klass}'")
    end
  end

  def equal(obj2)
    lambda do |obj, res|
      __assert__(obj.equal?(obj2), res, "Expected `#{obj}' to be equal? `#{obj2}'")
    end
  end

  def respond_to(sel)
    lambda do |obj, res|
      __assert__(obj.respond_to?(sel), res, "Expected `#{obj}' to respond_to? `#{sel}'")
    end
  end

  def be_nil
    lambda do |obj, res|
      __assert__(obj == nil, res, "Expected `#{obj}' to be nil'")
    end
  end

  def be_true
    lambda do |obj, res|
      __assert__(obj == true, res, "Expected `#{obj}' to be true'")
    end
  end

  def be_false
    lambda do |obj, res|
      __assert__(obj == false, res, "Expected `#{obj}' to be false'")
    end
  end

  def raise_error(klass)
    lambda do |obj, res|
      begin
        obj.call
        __assert__(!res, true, "Expected `#{klass}' to be raised, but nothing happened")
      rescue Exception => e
        __assert__(e.is_a?(klass), res, "Expected `#{klass}' to be raised, got `#{e}'")
      end
    end
  end

  TOLERANCE = 0.00003
  def be_close(expected, tolerance)
    lambda do |obj, res|
      __assert__((obj - expected).abs < tolerance, res, "Expected `#{obj}' to be within `#{expected}' of tolerance `#{tolerance}'")
    end
  end

  def mock(obj)
    # XXX we probably should be smarter here.
    obj
  end

  def nan_value
    0/0.0
  end

  def infinity_value
    1/0.0
  end

  def bignum_value(plus=0)
    0x8000_0000_0000_0000 + plus
  end
end

class MainActivity < Android::App::Activity
  def onCreate(savedInstanceState)
    super
    Exception.log_exceptions = false
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
