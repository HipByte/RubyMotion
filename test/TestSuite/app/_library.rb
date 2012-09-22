Exception.log_exceptions = false
$testsuite_error = 0
$testsuite_failure = 0

def test_begin(filename)
  filename = sprintf("%+20s : ", filename)
  print filename
end

def test_end
  puts ""
end

def assert_check(testsrc, message = '', opt = '')
  result = testsrc.call
  faildesc = yield(result)
  if !faildesc
    print '.'
  else
    print 'F'
    $testsuite_failure += 1
  end
rescue Exception => err
  print 'E'
  NSLog err.message
  $testsuite_error += 1
end

def assert_equal(expected, testsrc, message = '')
  assert_check(testsrc, message, nil) {|result|
    if expected == result.to_s
      nil
    else
      desc = "#{result.inspect} (expected #{expected.inspect})"
      NSLog desc
    end
  }
end

def assert_match(expected_pattern, testsrc, message = '')
  assert_check(testsrc, message) {|result|
    if expected_pattern =~ result
      nil
    else
      desc = "#{expected_pattern.inspect} expected to be =~\n#{result.inspect}"
      NSLog desc
    end
  }
end
