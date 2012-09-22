test_begin "test_syntax"

assert_equal %q{4}, proc{1 && 2 && 3 && 4}
assert_equal %q{}, proc{1 && nil && 3 && 4}
assert_equal %q{}, proc{1 && 2 && 3 && nil}
assert_equal %q{false}, proc{1 && 2 && 3 && false}
assert_equal %q{4}, proc{1 and 2 and 3 and 4}
assert_equal %q{}, proc{1 and nil and 3 and 4}
assert_equal %q{}, proc{1 and 2 and 3 and nil}
assert_equal %q{false}, proc{1 and 2 and 3 and false}
assert_equal %q{}, proc{nil && true}
assert_equal %q{false}, proc{false && true}
assert_equal %q{}, proc{
  case 1
  when 2
    :ng
  end}
assert_equal %q{ok}, proc{
  case 1
  when 10,20,30
    :ng1
  when 1,2,3
    :ok
  when 100,200,300
    :ng2
  else
    :elseng
  end}
assert_equal %q{elseok}, proc{
  case 123
  when 10,20,30
    :ng1
  when 1,2,3
    :ng2
  when 100,200,300
    :ng3
  else
    :elseok
  end
}
assert_equal %q{ok}, proc{
  case 'test'
  when /testx/
    :ng1
  when /test/
    :ok
  when /tetxx/
    :ng2
  else
    :ng_else
  end
}
assert_equal %q{ok}, proc{
  case Object.new
  when Object
    :ok
  end
}
assert_equal %q{ok}, proc{
  case Object
  when Object.new
    :ng
  else
    :ok
  end
}
assert_equal %q{ok}, proc{
  case 'test'
  when 'tes'
    :ng
  when 'te'
    :ng
  else
    :ok
  end
}
assert_equal %q{ok}, proc{
  case 'test'
  when 'tes'
    :ng
  when 'te'
    :ng
  when 'test'
    :ok
  end
}
assert_equal %q{ng}, proc{
  case 'test'
  when 'tes'
    :ng
  when /te/
    :ng
  else
    :ok
  end
}
assert_equal %q{ok}, proc{
  case 'test'
  when 'tes'
    :ng
  when /test/
    :ok
  else
    :ng
  end
}
assert_equal %q{100}, proc{
  def test(arg)
    case 1
    when 2
      3
    end
    return arg
  end
  
  test(100)
}
assert_equal %q{ok}, proc{
  ary = [1, 2]
  case 1
  when *ary
    :ok
  else
    :ng
  end
}
assert_equal %q{ok}, proc{
  ary = [1, 2]
  case 3
  when *ary
    :ng
  else
    :ok
  end
}
# assert_equal %q{ok}, proc{
#   ary = [1, 2]
#   case 1
#   when :x, *ary
#     :ok
#   when :z
#     :ng1
#   else
#     :ng2
#   end
# }
# assert_equal %q{ok}, proc{
#   ary = [1, 2]
#   case 3
#   when :x, *ary
#     :ng1
#   when :z
#     :ng2
#   else
#     :ok
#   end
# }
# assert_equal %q{[:false, :false, :false, :false, :false, :false, :false, :false, :false, :false, :false, :then, :false, :false, :false, :then, :false, :false, :false, :then, :false, :false, :false, :then, :false, :false, :then, :then, :false, :false, :then, :then, :false, :false, :then, :then, :false, :false, :then, :then, :false, :then, :then, :then, :false, :then, :then, :then, :false, :then, :then, :then, :false, :then, :then, :then, :then, :then, :then, :then, :then, :then, :then, :then, :false, :false, :false, :then, :false, :false, :false, :then, :false, :false, :false, :false, :false, :false, :false, :false, :false, :false, :then, :then, :false, :false, :then, :then, :false, :false, :false, :then, :false, :false, :false, :then, :false, :then, :then, :then, :false, :then, :then, :then, :false, :false, :then, :then, :false, :false, :then, :then, :then, :then, :then, :then, :then, :then, :then, :then, :false, :then, :then, :then, :false, :then, :then, :then, :false, :false, :false, :then, :false, :false, :false, :then, :false, :false, :then, :then, :false, :false, :then, :then, :false, :false, :false, :false, :false, :false, :false, :false, :false, :false, :false, :then, :false, :false, :false, :then, :false, :then, :then, :then, :false, :then, :then, :then, :then, :then, :then, :then, :then, :then, :then, :then, :false, :false, :then, :then, :false, :false, :then, :then, :false, :then, :then, :then, :false, :then, :then, :then, :false, :false, :then, :then, :false, :false, :then, :then, :false, :false, :false, :then, :false, :false, :false, :then, :false, :false, :false, :then, :false, :false, :false, :then, :false, :false, :false, :false, :false, :false, :false, :false, :then, :then, :then, :then, :then, :then, :then, :then, :false, :then, :then, :then, :false, :then, :then, :then, :false, :then, :then, :then, :false, :then, :then, :then, :false, :false, :then, :then, :false, :false, :then, :then, :false, :false, :then, :then, :false, :false, :then, :then, :false, :then, :then, :then, :false, :then, :then, :then, :false, :then, :then, :then, :false, :then, :then, :then, :then, :then, :then, :then, :then, :then, :then, :then, :false, :false, :false, :false, :false, :false, :false, :false, :false, :false, :false, :then, :false, :false, :false, :then, :false, :false, :false, :then, :false, :false, :false, :then, :false, :false, :then, :then, :false, :false, :then, :then, :false, :then, :then, :then, :false, :then, :then, :then, :false, :false, :then, :then, :false, :false, :then, :then, :then, :then, :then, :then, :then, :then, :then, :then, :false, :then, :then, :then, :false, :then, :then, :then, :false, :false, :false, :then, :false, :false, :false, :then, :false, :false, :false, :false, :false, :false, :false, :false, :false, :false, :then, :then, :false, :false, :then, :then, :false, :false, :false, :then, :false, :false, :false, :then, :false, :then, :then, :then, :false, :then, :then, :then, :then, :then, :then, :then, :then, :then, :then, :then, :false, :false, :then, :then, :false, :false, :then, :then, :false, :then, :then, :then, :false, :then, :then, :then, :false, :false, :false, :then, :false, :false, :false, :then, :false, :false, :then, :then, :false, :false, :then, :then, :false, :false, :false, :false, :false, :false, :false, :false, :false, :false, :false, :then, :false, :false, :false, :then, :then, :then, :then, :then, :then, :then, :then, :then, :false, :then, :then, :then, :false, :then, :then, :then, :false, :then, :then, :then, :false, :then, :then, :then, :false, :false, :then, :then, :false, :false, :then, :then, :false, :false, :then, :then, :false, :false, :then, :then, :false, :false, :false, :then, :false, :false, :false, :then, :false, :false, :false, :then, :false, :false, :false, :then, :false, :false, :false, :false, :false, :false, :false, :false, :then, :then, :then, :then, :then, :then, :then, :then, :then, :then, :then, :false, :then, :then, :then, :false, :then, :then, :then, :false, :then, :then, :then, :false, :then, :then, :false, :false, :then, :then, :false, :false, :then, :then, :false, :false, :then, :then, :false, :false, :then, :false, :false, :false, :then, :false, :false, :false, :then, :false, :false, :false, :then, :false, :false, :false, :false, :false, :false, :false, :false, :false, :false, :false, :then, :then, :then, :false, :then, :then, :then, :false, :then, :then, :then, :then, :then, :then, :then, :then, :then, :then, :false, :false, :then, :then, :false, :false, :then, :then, :then, :false, :then, :then, :then, :false, :then, :false, :false, :false, :then, :false, :false, :false, :then, :then, :false, :false, :then, :then, :false, :false, :false, :false, :false, :false, :false, :false, :false, :false, :then, :false, :false, :false, :then, :false, :false, :false, :then, :then, :then, :false, :then, :then, :then, :false, :then, :then, :false, :false, :then, :then, :false, :false, :then, :then, :then, :then, :then, :then, :then, :then, :then, :then, :then, :false, :then, :then, :then, :false, :then, :false, :false, :false, :then, :false, :false, :false, :false, :false, :false, :false, :false, :false, :false, :false, :then, :then, :false, :false, :then, :then, :false, :false, :then, :false, :false, :false, :then, :false, :false, :false, :then, :then, :false, :false, :then, :then, :false, :false, :then, :then, :then, :false, :then, :then, :then, :false, :then, :then, :then, :false, :then, :then, :then, :false, :then, :then, :then, :then, :then, :then, :then, :then, :false, :false, :false, :false, :false, :false, :false, :false, :then, :false, :false, :false, :then, :false, :false, :false, :then, :false, :false, :false, :then, :false, :false, :false, :then, :then, :false, :false, :then, :then, :false, :false, :then, :then, :false, :false, :then, :then, :false, :false, :then, :false, :false, :false, :then, :false, :false, :false, :then, :false, :false, :false, :then, :false, :false, :false, :false, :false, :false, :false, :false, :false, :false, :false, :then, :then, :then, :then, :then, :then, :then, :then, :then, :then, :then, :false, :then, :then, :then, :false, :then, :then, :then, :false, :then, :then, :then, :false, :then, :then, :false, :false, :then, :then, :false, :false, :then, :false, :false, :false, :then, :false, :false, :false, :then, :then, :false, :false, :then, :then, :false, :false, :false, :false, :false, :false, :false, :false, :false, :false, :then, :false, :false, :false, :then, :false, :false, :false, :then, :then, :then, :false, :then, :then, :then, :false, :then, :then, :then, :then, :then, :then, :then, :then, :then, :then, :false, :false, :then, :then, :false, :false, :then, :then, :then, :false, :then, :then, :then, :false, :then, :false, :false, :false, :then, :false, :false, :false, :false, :false, :false, :false, :false, :false, :false, :false, :then, :then, :false, :false, :then, :then, :false, :false, :then, :false, :false, :false, :then, :false, :false, :false, :then, :then, :then, :false, :then, :then, :then, :false, :then, :then, :false, :false, :then, :then, :false, :false, :then, :then, :then, :then, :then, :then, :then, :then, :then, :then, :then, :false, :then, :then, :then, :false, :false, :false, :false, :false, :false, :false, :false, :false, :then, :false, :false, :false, :then, :false, :false, :false, :then, :false, :false, :false, :then, :false, :false, :false, :then, :then, :false, :false, :then, :then, :false, :false, :then, :then, :false, :false, :then, :then, :false, :false, :then, :then, :then, :false, :then, :then, :then, :false, :then, :then, :then, :false, :then, :then, :then, :false, :then, :then, :then, :then, :then, :then, :then, :then, :sep, :sep, :sep, :sep, :sep, :sep, :sep, :sep, :sep, :sep, :sep, :then, :sep, :sep, :sep, :sep, :then, :sep, :sep, :sep, :sep, :then, :sep, :sep, :sep, :sep, :then, :sep, :sep, :sep, :then, :sep, :then, :sep, :sep, :sep, :then, :sep, :then, :sep, :sep, :sep, :then, :sep, :then, :sep, :sep, :sep, :then, :sep, :then, :sep, :sep, :then, :sep, :then, :sep, :then, :sep, :sep, :then, :sep, :then, :sep, :then, :sep, :sep, :then, :sep, :then, :sep, :then, :sep, :sep, :then, :sep, :then, :sep, :then, :sep, :then, :sep, :then, :sep, :then, :sep, :then, :sep, :then, :sep, :then, :sep, :then, :sep, :then, :sep, :sep, :sep, :sep, :then, :sep, :sep, :sep, :sep, :then, :sep, :sep, :sep, :sep, :sep, :sep, :sep, :sep, :sep, :sep, :sep, :then, :sep, :then, :sep, :sep, :sep, :then, :sep, :then, :sep, :sep, :sep, :sep, :then, :sep, :sep, :sep, :sep, :then, :sep, :sep, :then, :sep, :then, :sep, :then, :sep, :sep, :then, :sep, :then, :sep, :then, :sep, :sep, :sep, :then, :sep, :then, :sep, :sep, :sep, :then, :sep, :then, :sep, :then, :sep, :then, :sep, :then, :sep, :then, :sep, :then, :sep, :then, :sep, :then, :sep, :then, :sep, :sep, :then, :sep, :then, :sep, :then, :sep, :sep, :then, :sep, :then, :sep, :then, :sep, :sep, :sep, :sep, :then, :sep, :sep, :sep, :sep, :then, :sep, :sep, :sep, :then, :sep, :then, :sep, :sep, :sep, :then, :sep, :then, :sep, :sep, :sep, :sep, :sep, :sep, :sep, :sep, :sep, :sep, :sep, :sep, :then, :sep, :sep, :sep, :sep, :then, :sep, :sep, :then, :sep, :then, :sep, :then, :sep, :sep, :then, :sep, :then, :sep, :then, :sep, :then, :sep, :then, :sep, :then, :sep, :then, :sep, :then, :sep, :then, :sep, :then, :sep, :then, :sep, :sep, :sep, :then, :sep, :then, :sep, :sep, :sep, :then, :sep, :then, :sep, :sep, :then, :sep, :then, :sep, :then, :sep, :sep, :then, :sep, :then, :sep, :then, :sep, :sep, :sep, :then, :sep, :then, :sep, :sep, :sep, :then, :sep, :then, :sep, :sep, :sep, :sep, :then, :sep, :sep, :sep, :sep, :then, :sep, :sep, :sep, :sep, :then, :sep, :sep, :sep, :sep, :then, :sep, :sep, :sep, :sep, :sep, :sep, :sep, :sep, :sep, :then, :sep, :then, :sep, :then, :sep, :then, :sep, :then, :sep, :then, :sep, :then, :sep, :then, :sep, :sep, :then, :sep, :then, :sep, :then, :sep, :sep, :then, :sep, :then, :sep, :then, :sep, :sep, :then, :sep, :then, :sep, :then, :sep, :sep, :then, :sep, :then, :sep, :then, :sep, :sep, :sep, :then, :sep, :then, :sep, :sep, :sep, :then, :sep, :then, :sep, :sep, :sep, :then, :sep, :then, :sep, :sep, :sep, :then, :sep, :then, :sep, :sep, :then, :sep, :then, :sep, :then, :sep, :sep, :then, :sep, :then, :sep, :then, :sep, :sep, :then, :sep, :then, :sep, :then, :sep, :sep, :then, :sep, :then, :sep, :then, :sep, :then, :sep, :then, :sep, :then, :sep, :then, :sep, :then, :sep, :then, :sep, :then, :sep, :then, :sep, :sep, :sep, :sep, :sep, :sep, :sep, :sep, :sep, :sep, :sep, :sep, :then, :sep, :sep, :sep, :sep, :then, :sep, :sep, :sep, :sep, :then, :sep, :sep, :sep, :sep, :then, :sep, :sep, :sep, :then, :sep, :then, :sep, :sep, :sep, :then, :sep, :then, :sep, :sep, :then, :sep, :then, :sep, :then, :sep, :sep, :then, :sep, :then, :sep, :then, :sep, :sep, :sep, :then, :sep, :then, :sep, :sep, :sep, :then, :sep, :then, :sep, :then, :sep, :then, :sep, :then, :sep, :then, :sep, :then, :sep, :then, :sep, :then, :sep, :then, :sep, :sep, :then, :sep, :then, :sep, :then, :sep, :sep, :then, :sep, :then, :sep, :then, :sep, :sep, :sep, :sep, :then, :sep, :sep, :sep, :sep, :then, :sep, :sep, :sep, :sep, :sep, :sep, :sep, :sep, :sep, :sep, :sep, :then, :sep, :then, :sep, :sep, :sep, :then, :sep, :then, :sep, :sep, :sep, :sep, :then, :sep, :sep, :sep, :sep, :then, :sep, :sep, :then, :sep, :then, :sep, :then, :sep, :sep, :then, :sep, :then, :sep, :then, :sep, :then, :sep, :then, :sep, :then, :sep, :then, :sep, :then, :sep, :then, :sep, :then, :sep, :then, :sep, :sep, :sep, :then, :sep, :then, :sep, :sep, :sep, :then, :sep, :then, :sep, :sep, :then, :sep, :then, :sep, :then, :sep, :sep, :then, :sep, :then, :sep, :then, :sep, :sep, :sep, :sep, :then, :sep, :sep, :sep, :sep, :then, :sep, :sep, :sep, :then, :sep, :then, :sep, :sep, :sep, :then, :sep, :then, :sep, :sep, :sep, :sep, :sep, :sep, :sep, :sep, :sep, :sep, :sep, :sep, :then, :sep, :sep, :sep, :sep, :then, :sep, :then, :sep, :then, :sep, :then, :sep, :then, :sep, :then, :sep, :then, :sep, :then, :sep, :then, :sep, :sep, :then, :sep, :then, :sep, :then, :sep, :sep, :then, :sep, :then, :sep, :then, :sep, :sep, :then, :sep, :then, :sep, :then, :sep, :sep, :then, :sep, :then, :sep, :then, :sep, :sep, :sep, :then, :sep, :then, :sep, :sep, :sep, :then, :sep, :then, :sep, :sep, :sep, :then, :sep, :then, :sep, :sep, :sep, :then, :sep, :then, :sep, :sep, :sep, :sep, :then, :sep, :sep, :sep, :sep, :then, :sep, :sep, :sep, :sep, :then, :sep, :sep, :sep, :sep, :then, :sep, :sep, :sep, :sep, :sep, :sep, :sep, :sep, :sep, :then, :sep, :then, :sep, :then, :sep, :then, :sep, :then, :sep, :then, :sep, :then, :sep, :then, :sep, :then, :sep, :then, :sep, :then, :sep, :sep, :then, :sep, :then, :sep, :then, :sep, :sep, :then, :sep, :then, :sep, :then, :sep, :sep, :then, :sep, :then, :sep, :then, :sep, :sep, :then, :sep, :then, :sep, :sep, :sep, :then, :sep, :then, :sep, :sep, :sep, :then, :sep, :then, :sep, :sep, :sep, :then, :sep, :then, :sep, :sep, :sep, :then, :sep, :sep, :sep, :sep, :then, :sep, :sep, :sep, :sep, :then, :sep, :sep, :sep, :sep, :then, :sep, :sep, :sep, :sep, :sep, :sep, :sep, :sep, :sep, :sep, :sep, :sep, :then, :sep, :then, :sep, :then, :sep, :sep, :then, :sep, :then, :sep, :then, :sep, :sep, :then, :sep, :then, :sep, :then, :sep, :then, :sep, :then, :sep, :then, :sep, :then, :sep, :then, :sep, :then, :sep, :then, :sep, :sep, :sep, :then, :sep, :then, :sep, :sep, :sep, :then, :sep, :then, :sep, :then, :sep, :sep, :then, :sep, :then, :sep, :then, :sep, :sep, :then, :sep, :sep, :sep, :sep, :then, :sep, :sep, :sep, :sep, :then, :sep, :then, :sep, :sep, :sep, :then, :sep, :then, :sep, :sep, :sep, :sep, :sep, :sep, :sep, :sep, :sep, :sep, :sep, :then, :sep, :sep, :sep, :sep, :then, :sep, :sep, :sep, :sep, :then, :sep, :then, :sep, :then, :sep, :sep, :then, :sep, :then, :sep, :then, :sep, :sep, :then, :sep, :then, :sep, :sep, :sep, :then, :sep, :then, :sep, :sep, :sep, :then, :sep, :then, :sep, :then, :sep, :then, :sep, :then, :sep, :then, :sep, :then, :sep, :then, :sep, :then, :sep, :then, :sep, :then, :sep, :sep, :then, :sep, :then, :sep, :then, :sep, :sep, :then, :sep, :sep, :sep, :sep, :then, :sep, :sep, :sep, :sep, :sep, :sep, :sep, :sep, :sep, :sep, :sep, :sep, :then, :sep, :then, :sep, :sep, :sep, :then, :sep, :then, :sep, :sep, :sep, :then, :sep, :sep, :sep, :sep, :then, :sep, :sep, :sep, :sep, :then, :sep, :then, :sep, :sep, :sep, :then, :sep, :then, :sep, :sep, :sep, :then, :sep, :then, :sep, :then, :sep, :sep, :then, :sep, :then, :sep, :then, :sep, :sep, :then, :sep, :then, :sep, :then, :sep, :sep, :then, :sep, :then, :sep, :then, :sep, :sep, :then, :sep, :then, :sep, :then, :sep, :then, :sep, :then, :sep, :then, :sep, :then, :sep, :then, :sep, :sep, :sep, :sep, :sep, :sep, :sep, :sep, :sep, :then, :sep, :sep, :sep, :sep, :then, :sep, :sep, :sep, :sep, :then, :sep, :sep, :sep, :sep, :then, :sep, :sep, :sep, :sep, :then, :sep, :then, :sep, :sep, :sep, :then, :sep, :then, :sep, :sep, :sep, :then, :sep, :then, :sep, :sep, :sep, :then, :sep, :then, :sep, :sep, :sep, :then, :sep, :sep, :sep, :sep, :then, :sep, :sep, :sep, :sep, :then, :sep, :sep, :sep, :sep, :then, :sep, :sep, :sep, :sep, :sep, :sep, :sep, :sep, :sep, :sep, :sep, :sep, :then, :sep, :then, :sep, :then, :sep, :then, :sep, :then, :sep, :then, :sep, :then, :sep, :then, :sep, :then, :sep, :then, :sep, :then, :sep, :sep, :then, :sep, :then, :sep, :then, :sep, :sep, :then, :sep, :then, :sep, :then, :sep, :sep, :then, :sep, :then, :sep, :then, :sep, :sep, :then, :sep, :then, :sep, :sep, :sep, :then, :sep, :then, :sep, :sep, :sep, :then, :sep, :sep, :sep, :sep, :then, :sep, :sep, :sep, :sep, :then, :sep, :then, :sep, :sep, :sep, :then, :sep, :then, :sep, :sep, :sep, :sep, :sep, :sep, :sep, :sep, :sep, :sep, :sep, :then, :sep, :sep, :sep, :sep, :then, :sep, :sep, :sep, :sep, :then, :sep, :then, :sep, :then, :sep, :sep, :then, :sep, :then, :sep, :then, :sep, :sep, :then, :sep, :then, :sep, :then, :sep, :then, :sep, :then, :sep, :then, :sep, :then, :sep, :then, :sep, :then, :sep, :then, :sep, :sep, :sep, :then, :sep, :then, :sep, :sep, :sep, :then, :sep, :then, :sep, :then, :sep, :sep, :then, :sep, :then, :sep, :then, :sep, :sep, :then, :sep, :sep, :sep, :sep, :then, :sep, :sep, :sep, :sep, :sep, :sep, :sep, :sep, :sep, :sep, :sep, :sep, :then, :sep, :then, :sep, :sep, :sep, :then, :sep, :then, :sep, :sep, :sep, :then, :sep, :sep, :sep, :sep, :then, :sep, :sep, :sep, :sep, :then, :sep, :then, :sep, :then, :sep, :sep, :then, :sep, :then, :sep, :then, :sep, :sep, :then, :sep, :then, :sep, :sep, :sep, :then, :sep, :then, :sep, :sep, :sep, :then, :sep, :then, :sep, :then, :sep, :then, :sep, :then, :sep, :then, :sep, :then, :sep, :then, :sep, :then, :sep, :then, :sep, :then, :sep, :sep, :then, :sep, :then, :sep, :then, :sep, :sep, :sep, :sep, :sep, :sep, :sep, :sep, :sep, :sep, :then, :sep, :sep, :sep, :sep, :then, :sep, :sep, :sep, :sep, :then, :sep, :sep, :sep, :sep, :then, :sep, :sep, :sep, :sep, :then, :sep, :then, :sep, :sep, :sep, :then, :sep, :then, :sep, :sep, :sep, :then, :sep, :then, :sep, :sep, :sep, :then, :sep, :then, :sep, :sep, :sep, :then, :sep, :then, :sep, :then, :sep, :sep, :then, :sep, :then, :sep, :then, :sep, :sep, :then, :sep, :then, :sep, :then, :sep, :sep, :then, :sep, :then, :sep, :then, :sep, :sep, :then, :sep, :then, :sep, :then, :sep, :then, :sep, :then, :sep, :then, :sep, :then, :sep, :then, :sep]}, proc{

#   def make_perm ary, num
#     if num == 1
#       ary.map{|e| [e]}
#     else
#       base = make_perm(ary, num-1)
#       res  = []
#       base.each{|b|
#         ary.each{|e|
#           res << [e] + b
#         }
#       }
#       res
#     end
#   end
  
#   def each_test
#     conds = make_perm(['fv', 'tv'], 3)
#     bangs = make_perm(['', '!'], 3)
#     exprs = make_perm(['and', 'or'], 3)
#     ['if', 'unless'].each{|syn|
#       conds.each{|cs|
#         bangs.each{|bs|
#           exprs.each{|es|
#             yield(syn, cs, bs, es)
#           }
#         }
#       }
#     }
#   end
  
#   fv = false
#   tv = true
  
#   $ans = []
#   each_test{|syn, conds, bangs, exprs|
#     c1, c2, c3 = conds
#     bang1, bang2, bang3 = bangs
#     e1, e2 = exprs
#     eval %Q{
#       #{syn} #{bang1}#{c1} #{e1} #{bang2}#{c2} #{e2} #{bang3}#{c3}
#         $ans << :then
#       else
#         $ans << :false
#       end
#     }
#   }

#   each_test{|syn, conds, bangs, exprs|
#     c1, c2, c3 = conds
#     bang1, bang2, bang3 = bangs
#     e1, e2 = exprs
#     eval %Q{
#       #{syn} #{bang1}#{c1} #{e1} #{bang2}#{c2} #{e2} #{bang3}#{c3}
#         $ans << :then
#       end
#       $ans << :sep
#     }
#   }
#   $ans
# }
assert_equal %q{}, proc{
  defined?(mmmm)
}
assert_equal %q{method}, proc{
  def m
  end
  defined?(m)
}
assert_equal %q{}, proc{
  defined?(a.class)
}
assert_equal %q{method}, proc{
  a = 1
  defined?(a.class)
}
# assert_equal %q{["method", "method", "method", "method", nil, nil, "method", "method", "method", nil]}, proc{
#   class C
#     def test
#       [defined?(m1()), defined?(self.m1), defined?(C.new.m1),
#        defined?(m2()), defined?(self.m2), defined?(C.new.m2),
#        defined?(m3()), defined?(self.m3), defined?(C.new.m3)]
#     end
#     def m1
#     end
#     private
#     def m2
#     end
#     protected
#     def m3
#     end
#   end
#   C.new.test + [defined?(C.new.m3)]
# }
# assert_equal %q{[nil, nil, nil, nil, "global-variable", "global-variable", nil, nil]}, proc{
#   $ans = [defined?($1), defined?($2), defined?($3), defined?($4)]
#   /(a)(b)/ =~ 'ab'
#   $ans + [defined?($1), defined?($2), defined?($3), defined?($4)]
# }
# assert_equal %q{nilselftruefalse}, proc{
#   defined?(nil) + defined?(self) +
#     defined?(true) + defined?(false)
# }
assert_equal %q{}, proc{
  defined?(@a)
}
assert_equal %q{instance-variable}, proc{
  @a = 1
  defined?(@a)
}
assert_equal %q{}, proc{
  defined?(@@a)
}
assert_equal %q{class variable}, proc{
  @@a = 1
  defined?(@@a)
}
# assert_equal %q{}, proc{
#   defined?($a)
# }
# assert_equal %q{global-variable}, proc{
#   $a = 1
#   defined?($a)
# }
assert_equal %q{}, proc{
  defined?(C_definedtest)
}
assert_equal %q{constant}, proc{
  C_definedtest = 1
  defined?(C_definedtest)
}
assert_equal %q{}, proc{
  defined?(::C_definedtest1)
}
assert_equal %q{constant}, proc{
  C_definedtest1 = 1
  defined?(::C_definedtest1)
}
assert_equal %q{}, proc{
  defined?(C_definedtestA::C_definedtestB::C_definedtestC)
}
assert_equal %q{constant}, proc{
  class C_definedtestA
    class C_definedtestB
      C_definedtestC = 1
    end
  end
  defined?(C_definedtestA::C_definedtestB::C_definedtestC)
}
assert_equal %q{30}, proc{
  sum = 0
  30.times{|ib|
    if ib % 10 == 0 .. true
      sum += ib
    end
  }
  sum
}
assert_equal %q{63}, proc{
  sum = 0
  30.times{|ib|
    if ib % 10 == 0 ... true
      sum += ib
    end
  }
  sum
}
# assert_equal %q{[["NUM", "Type: NUM\n"], ["NUM", "123\n"], ["NUM", "456\n"], ["NUM", "Type: ARP\n"], ["NUM", "aaa\n"], ["NUM", "bbb\n"], ["NUM", "\f\n"], ["ARP", "Type: ARP\n"], ["ARP", "aaa\n"], ["ARP", "bbb\n"]]}, proc{
#   t = nil
#   unless ''.respond_to? :lines
#     class String
#       def lines
#         self
#       end
#     end
#   end
#   ary = []
# "this must not print
# Type: NUM
# 123
# 456
# Type: ARP
# aaa
# bbb
# \f
# this must not print
# hoge
# Type: ARP
# aaa
# bbb
# ".lines.each{|l|
#     if (t = l[/^Type: (.*)/, 1])..(/^\f/ =~ l)
#       ary << [t, l]
#     end
#   }
#   ary
# }
assert_equal %q{1}, proc{if true  then 1 ; end}
assert_equal %q{}, proc{if false then 1 ; end}
assert_equal %q{1}, proc{if true  then 1 ; else; 2; end}
assert_equal %q{2}, proc{if false then 1 ; else; 2; end}
assert_equal %q{}, proc{if true  then   ; elsif true then ; 1 ; end}
assert_equal %q{1}, proc{if false then   ; elsif true then ; 1 ; end}
assert_equal %q{}, proc{unless true  then 1 ; end}
assert_equal %q{1}, proc{unless false then 1 ; end}
assert_equal %q{2}, proc{unless true  then 1 ; else; 2; end}
assert_equal %q{1}, proc{unless false then 1 ; else; 2; end}
assert_equal %q{1}, proc{1 if true}
assert_equal %q{}, proc{1 if false}
assert_equal %q{}, proc{1 if nil}
assert_equal %q{}, proc{1 unless true}
assert_equal %q{1}, proc{1 unless false}
assert_equal %q{1}, proc{1 unless nil}
assert_equal %q{1}, proc{1 || 2 || 3 || 4}
assert_equal %q{1}, proc{1 || false || 3 || 4}
assert_equal %q{2}, proc{nil || 2 || 3 || 4}
assert_equal %q{2}, proc{false || 2 || 3 || 4}
assert_equal %q{false}, proc{nil || false || nil || false}
assert_equal %q{1}, proc{1 or 2 or 3 or 4}
assert_equal %q{1}, proc{1 or false or 3 or 4}
assert_equal %q{2}, proc{nil or 2 or 3 or 4}
assert_equal %q{2}, proc{false or 2 or 3 or 4}
assert_equal %q{false}, proc{nil or false or nil or false}
assert_equal %q{elseng}, proc{
  case
  when 1==2, 2==3
    :ng1
  when false, 4==5
    :ok
  when false
    :ng2
  else
    :elseng
  end
}
assert_equal %q{ok}, proc{
  case
  when nil, nil
    :ng1
  when 1,2,3
    :ok
  when false, false
    :ng2
  else
    :elseng
  end
}
assert_equal %q{elseok}, proc{
  case
  when nil
    :ng1
  when false
    :ng2
  else
    :elseok
  end}
assert_equal %q{}, proc{
  case
  when 1
  end
}
# assert_equal %q{ok}, proc{
#   r = nil
#   ary = []
#   case
#   when false
#     r = :ng1
#   when false, false
#     r = :ng2
#   when *ary
#     r = :ng3
#   when false, *ary
#     r = :ng4
#   when true, *ary
#     r = :ok
#   end
#   r
# }
# assert_equal %q{ok}, proc{
#   ary = []
#   case
#   when false, *ary
#     :ng
#   else
#     :ok
#   end
# }
# assert_equal %q{ok}, proc{
#   ary = [false, nil]
#   case
#   when *ary
#     :ng
#   else
#     :ok
#   end
# }
# assert_equal %q{ok}, proc{
#   ary = [false, nil]
#   case
#   when *ary
#     :ng
#   when true
#     :ok
#   else
#     :ng2
#   end
# }
# assert_equal %q{ng}, proc{
#   ary = [false, nil]
#   case
#   when *ary
#     :ok
#   else
#     :ng
#   end
# }
assert_equal %q{ok}, proc{
  ary = [false, true]
  case
  when *ary
    :ok
  else
    :ng
  end
}
assert_equal %q{ok}, proc{
  ary = [false, true]
  case
  when false, false
  when false, *ary
    :ok
  else
    :ng
  end
}
assert_equal %q{}, proc{
  i = 0
  while i < 10
    i+=1
  end}
assert_equal %q{10}, proc{
  i = 0
  while i < 10
    i+=1
  end; i}
assert_equal %q{}, proc{
  i = 0
  until i > 10
    i+=1
  end}
assert_equal %q{11}, proc{
  i = 0
  until i > 10
    i+=1
  end; i}
assert_equal %q{1}, proc{
  i = 0
  begin
    i+=1
  end while false
  i
}
assert_equal %q{1}, proc{
  i = 0
  begin
    i+=1
  end until true
  i
}
# def assert_syntax_error expected, code, message = ''
#   assert_equal "#{expected}",
#     "begin eval(%q{#{code}}, nil, '', 0)"'; rescue SyntaxError => e; e.message[/\A:(?:\d+:)? (.*)/, 1] end', message
# end
# assert_syntax_error "unterminated string meets end of file", '().."', '[ruby-dev:29732]'
assert_equal %q{[]}, proc{$&;[]}, '[ruby-dev:31068]'
# assert_syntax_error "syntax error, unexpected tSTAR, expecting '}'", proc{{*0}}, '[ruby-dev:31072]'
# assert_syntax_error "`@0' is not allowed as an instance variable name", proc{@0..0}, '[ruby-dev:31095]'
# assert_syntax_error "identifier $00 is not valid to get", proc{$00..0}, '[ruby-dev:31100]'
# assert_syntax_error "identifier $00 is not valid to set", proc{0..$00=1}
assert_equal %q{0}, proc{[*0];0}, '[ruby-dev:31102]'
# assert_syntax_error "syntax error, unexpected ')'", proc{v0,(*,v1,) = 0}, '[ruby-dev:31104]'
# assert_equal %q{1}, proc{
#   class << (ary=[]); def []; 0; end; def []=(x); super(0,x);end;end; ary[]+=1
# }, '[ruby-dev:31110]'
# assert_syntax_error "Can't set variable $1", proc{0..$1=1}, '[ruby-dev:31118]'
# assert_valid_syntax %q{1.times{1+(1&&next)}}, '[ruby-dev:31119]'
# assert_valid_syntax %q{x=-1;loop{x+=1&&redo if (x+=1).zero?}}, '[ruby-dev:31119]'
# assert_syntax_error %q{syntax error, unexpected $end}, proc{!}, '[ruby-dev:31243]'
assert_equal %q{[nil]}, proc{[()]}, '[ruby-dev:31252]'
assert_equal %q{true}, proc{!_=()}, '[ruby-dev:31263]'
assert_equal 'ok', proc{while true; redo; end if 1 == 2; :ok}, '[ruby-dev:31360]'
assert_equal 'ok', proc{
  1.times {
    begin
    ensure
      next
    end
  }; :ok
}, '[ruby-dev:31373]'
assert_equal 'ok', proc{
  flag = false
  1.times {
    next if flag
    flag = true
    begin
    ensure
      redo
    end
  }; :ok
}, '[ruby-dev:31373]'

assert_equal 'ok', proc{
  1.times{
    p(1, (next; 2))
  }; :ok
}
assert_equal '3', proc{
  i = 0
  1 + (while true
         break 2 if (i+=1) > 1
         next
       end)
}
assert_equal '3', proc{
  i = 0
  1 + (while true
         break 2 if (i+=1) > 1
         p(1, (next; 2))
       end)
}
# redo
assert_equal 'ok', proc{
  i = 0
  1.times{
    break if i>1
    i+=1
    p(1, (redo; 2))
  }; :ok
}
assert_equal '3', proc{
  i = 0
  1 + (while true
         break 2 if (i+=1) > 1
         redo
       end)
}
assert_equal '3', proc{
  i = 0
  1 + (while true
         break 2 if (i+=1) > 1
         p(1, (redo; 2))
       end)
}
# assert_equal '1', proc{
#   a = [0]
#   a[*a]+=1
# }
assert_equal '2', proc{
  ary = [0]
  case 1
  when *ary, 1
    1
  end +
  case
  when *ary
    1
  end
}

# assert_match /invalid multibyte char/, proc{
#   STDERR.reopen(STDOUT)
#   eval("\"\xf0".force_encoding("utf-8"))
# }, '[ruby-dev:32429]'

# method ! and !=
assert_equal 'true', proc{!false}
assert_equal 'true', proc{1 == 1}
assert_equal 'true', proc{1 != 2}
assert_equal 'true', proc{
  class C; def !=(obj); true; end; end
  C.new != 1
}
# assert_equal 'true', proc{
#   class C; def !@; true; end; end
#   !C.new
# }
# assert_normal_exit %q{
#   eval "while true; return; end rescue p $!"
# }, '[ruby-dev:31663]'
assert_equal '1', proc{
  def bar
    raise
  end

  def foo
    1.times{
      begin
        return bar
      rescue
        :ok
      end
    }
  end

  foo
}

assert_equal 'ok', proc{
  counter = 2
  while true
    counter -= 1
    next if counter != 0
    break
  end
  :ok
}, '[ruby-core:14385]'

assert_equal 'ok', proc{
  counter = 2
  while true
    counter -= 1
    next if counter != 0
    break :ok
  end # direct
}, '[ruby-core:14385]'

assert_equal 'ok', proc{
  counter = 2
  while true
    counter -= 1
    break if counter == 0
    "#{next}"
  end
  :ok
}, 'reported by Yusuke ENDOH'

assert_equal 'ok', proc{
  counter = 2
  while true
    counter -= 1
    break if counter == 0
    next 
    redo
  end
  :ok
}, 'reported by Yusuke ENDOH'

assert_equal 'ok', proc{
  counter = 2
  while true
    counter -= 1
    break if counter == 0
    next 
    "#{ redo }"
  end
  :ok
}, 'reported by Yusuke ENDOH'

# assert_normal_exit %q{
#   begin
#     raise
#   rescue
#     counter = 2
#     while true
#       counter -= 1
#       break if counter == 0
#       next
#       retry
#     end
#   end
# }, 'reported by Yusuke ENDOH'

# assert_normal_exit %q{
#   counter = 2
#   while true
#     counter -= 1
#     break if counter == 0
#     next
#     "#{ break }"
#   end
# }, 'reported by Yusuke ENDOH'

# assert_normal_exit %q{
#   counter = 2
#   while true
#     counter -= 1
#     next if counter != 0
#     "#{ break }"
#   end
# }, 'reported by Yusuke ENDOH'

assert_equal 'ok', proc{
  1.times do
    [
      1, 2, 3, 4, 5, 6, 7, 8,
      begin
        false ? next : p
        break while true
      end
    ]
  end
  :ok
}, '[ruby-dev:32882]'

# assert_equal "1\n2\n", proc{
#   i = 0
#   while i<2
#     i += 1
#     next p(i)
#   end
# }

# assert_valid_syntax('1.times {|i|print (42),1;}', '[ruby-list:44479]')

assert_equal 'ok', proc{
  def a() end
  begin
    if defined?(a(1).a)
      :ng
    else
      :ok
    end
  rescue
    :ng
  end
}, '[ruby-core:16010]'

assert_equal 'ok', proc{
  def a() end
  begin
    if defined?(a::B)
      :ng
    else
      :ok
    end
  rescue
    :ng
  end
}, '[ruby-core:16010]'

# assert_normal_exit %q{
#   defined? C && 0
# }

# assert_normal_exit %q{
#   class C
#     def m
#       defined?(super())
#     end
#   end
#   C.new.m
# }

assert_equal 'ok', proc{
  class X < RuntimeError;end
  x = [X]
  begin
   raise X
  rescue *x
   :ok
  end
}, '[ruby-core:14537]'

assert_equal 'ok', proc{
  a = [false]
  (a[0] &&= true) == false ? :ok : :ng
}, '[ruby-dev:34679]'

# assert_normal_exit %q{
#   a = []
#   100.times {|i| a << i << nil << nil }
#   p a.compact!
# }

assert_equal 'ok', proc{
  "#{}""#{}ok"
}, '[ruby-dev:38968]'


assert_equal 'ok', proc{
  "o" "#{}k"
}, '[ruby-dev:38980]'

# bug2415 = '[ruby-core:26961]'
# assert_normal_exit %q{
#   0.times do
#     0.times do
#       def x(a=1, b, *rest); nil end
#     end
#   end
# }, bug2415

# assert_normal_exit %q{
#   0.times do
#     0.times do
#       def x@; nil end
#     end
#   end
# }, bug2415

# assert_normal_exit %q{
#   0.times do
#     0.times do
#       def x(a = 0.times do
#               def y(a=1, b, *rest); nil; end
#             end)
#         nil
#       end
#     end
#   end
# }, bug2415

# assert_normal_exit %q{
#   0.times do
#     0.times do
#       def x(a = 0.times do
#               def x@; nil; end
#             end)
#         nil
#       end
#     end
#   end
# }, bug2415

# assert_normal_exit %q{
#   a {
#     b {|c.d| }
#     e
#   }
# }, '[ruby-dev:39861]'

# bug1240 = '[ruby-core:22637]'
# assert_valid_syntax('x y { "#{}".z { } }', bug1240)
# assert_valid_syntax('x y { "#{}".z do end }', bug1240)

# assert_valid_syntax('y "#{a 1}" do end', '[ruby-core:29579]')
# assert_normal_exit %q{
#   def foo(&block)
#     yield
#   end

#   foo do
#     s = defined?(raise + 1)
#     Class
#   end
# }, '[ruby-core:30293]'

test_end
