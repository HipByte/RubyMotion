class MainActivity < Android::App::Activity
  def onCreate(savedInstanceState)
    super
    @tests = @failures = 0
    test_class
    test_object
    test_boolean
    test_fixnum
    test_string
    test_array
    puts "Test suite finished: #{@tests} tests, #{@failures} failure(s)."
  end

  def test(msg, res)
    if res
      puts "OK : #{msg}"
    else
      puts "!! : #{msg}"
      @failures += 1
    end
    @tests += 1
  end

  def test_class
    test 'Class#inspect returns the Java class name', Java::Lang::Object.inspect == 'java.lang.Object'

    test 'Class#== returns true if both objects are equal', Java::Lang::Object == Java::Lang::Object
    test 'Class#== returns false if operand is a wrong class', (Java::Lang::Object == Java::Lang::String) == false
    test 'Class#== returns false if operand is not a class', (Java::Lang::Object == 42) == false
  end

  def test_object
    obj = Java::Lang::Object.new
    test 'Object#class returns Java::Lang::Object', obj.class == Java::Lang::Object
    test 'Object#inspect returns a string description', obj.inspect.class == Java::Lang::String # TODO test for actual content
    test 'Object.ancestors returns a correct array', obj.class.ancestors == [Java::Lang::Object]

    test 'Object#== returns true if both objects are equal', obj == obj
    test 'Object#== returns false if operand is not equal', (obj == Java::Lang::Object.new) == false

    test '!Object returns false', (!obj) == false
  end

  def test_boolean
    test 'true.class returns Java::Lang::Boolean', true.class == Java::Lang::Boolean
    test 'false.class returns Java::Lang::Boolean', false.class == Java::Lang::Boolean
    test '{true,false}.class.ancestors returns a correct array', true.class.ancestors == [Java::Lang::Boolean, Java::Lang::Object]
    test 'true.inspect returns \"true\"', true.inspect == 'true'
    test 'false.inspect returns \"false\"', false.inspect == 'false'
    
    test 'true#== returns true if operand is true', true == true
    test 'true#== returns false if operand is not true', (true == false) == false
    test 'false#== returns true if operand is false', false == false
    test 'false#== returns false if operand is not false', (false == true) == false

    test '!true returns false', !(true) == false
    test '!false returns true', !(false)
  end

  def test_fixnum
    test 'Fixnum#class returns Java::Lang::Long', 42.class == Java::Lang::Long
    test 'Fixnum.ancestors returns a correct array', 42.class.ancestors == [Java::Lang::Long, Java::Lang::Number, Java::Lang::Object]
    test 'Fixnum#inspect returns a string representation of the receiver', 42.inspect == '42' 

    test 'Fixnum#== returns true if both objects are equal', 42 == 42
    test 'Fixnum#== returns false if operand is a wrong fixnum', (42 == 100) == false
    test 'Fixnum#== returns false if operand is not a fixnum', (42 == '123') == false

    test 'Fixnum#+ returns the addition of the receiver and the operand', 31 + 11 == 42
    test 'Fixnum#- returns the substraction of the receiver and the operand', 63 - 21 == 42
    test 'Fixnum#* returns the multiplication of the receiver and the operand', 21 * 2 == 42
    test 'Fixnum#* returns the division of the receiver and the operand', 84 / 2 == 42

    test '!fixnum returns false', (!42) == false
  end

  def test_string
    test 'String#class returns Java::Lang::String', 'foo'.class == Java::Lang::String
    test 'String.ancestors returns a correct array', 'foo'.class.ancestors == [Java::Lang::String, Java::Lang::Object]
    test 'String#inspect returns an escaped string representation of the receiver', 'foo "hello world" bar'.inspect == "\"foo \\\"hello world\\\" bar\""
    test 'String#dup returns a copy of the receiver', 'foo'.dup == 'foo'

    test 'String#== returns true if both objects are equal', 'foo' == 'foo'
    test 'String#== returns false if operand is a wrong string', ('foo' == 'bar') == false
    test 'String#== returns false if operand is not a string', ('foo' == 42) == false

    test 'Literal strings can be interpolated', "foo #{'bar'}" == 'foo bar'
    x = 'foo'
    test '!string returns false', (!x) == false
  end

  def test_array
    test 'Array#class returns Java::Util::ArrayList', [].class == Java::Util::ArrayList
    test 'Array.ancestors returns a correct array', [].class.ancestors == [Java::Util::ArrayList, Java::Util::AbstractList, Java::Util::AbstractCollection, Java::Lang::Object]
    test 'Array#inspect returns a string representation of the receiver', [1, 2, 3].inspect == "[1, 2, 3]"
    test 'Array#dup returns a copy of the receiver', [1, 2, 3].dup == [1, 2, 3]

    test 'Array#== returns true if both objects are equal', [1, 2, 3] == [1, 1+1, 4-1]
    test 'Array#== returns false if operand is a wrong string', ([1, 2, 3] == [1, 2, 4]) == false
    test 'Array#== returns false if operand is not a string', ([1, 2, 3] == 42) == false

    a = [1, 2, 3]
    sum = 0
    a.each { |x| sum += x }
    test 'Array#each yields the block with each element', sum == 6

    test '!array returns false', (![42]) == false
  end
end
