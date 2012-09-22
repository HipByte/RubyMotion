test_begin "test_exception"

assert_equal %q{2}, proc{
  begin
    1+1
  ensure
    2+2
  end
}
assert_equal %q{4}, proc{
  begin
    1+1
    begin
      2+2
    ensure
      3+3
    end
  ensure
    4+4
  end
}
assert_equal %q{4}, proc{
  begin
    1+1
    begin
      2+2
    ensure
      3+3
    end
  ensure
    4+4
    begin
      5+5
    ensure
      6+6
    end
  end
}
assert_equal %q{NilClass}, proc{
  a = nil
  1.times{|e|
    begin
    rescue => err
    end
    a = err.class
  }
  a
}
assert_equal %q{RuntimeError}, proc{
  a = nil
  1.times{|e|
    begin
      raise
    rescue => err
    end
    a = err.class
  }
  a
}
assert_equal %q{}, proc{
  $!
}
assert_equal %q{FOO}, proc{
  begin
    raise "FOO"
  rescue
    $!
  end
}
assert_equal %q{FOO}, proc{
  def m
    $!
  end
  begin
    raise "FOO"
  rescue
    m()
  end
}
assert_equal %q{[#<RuntimeError: BAR>, #<RuntimeError: FOO>]}, proc{
  $ans = []
  def m
    $!
  end
  begin
    raise "FOO"
  rescue
    begin
      raise "BAR"
    rescue
      $ans << m()
    end
    $ans << m()
  end
  $ans
}
assert_equal %q{[#<RuntimeError: FOO>, #<RuntimeError: FOO>]}, proc{
  $ans = []
  def m
    $!
  end
  
  begin
    begin
      raise "FOO"
    ensure
      $ans << m()
    end
  rescue
    $ans << m()
  end
}
assert_equal %q{[nil]}, proc{
  $ans = []
  def m
    $!
  end
  def m2
    1.times{
      begin
        return
      ensure
        $ans << m
      end
    }
  end
  m2
  $ans
}
assert_equal %q{ok}, proc{
  begin
    raise
  rescue
    :ok
  end
}
assert_equal %q{ok}, proc{
  begin
    raise
  rescue
    :ok
  ensure
    :ng
  end
}
assert_equal %q{RuntimeError}, proc{
  begin
    raise
  rescue => e
    e.class
  end
}
assert_equal %q{ng}, proc{
  begin
    raise
  rescue StandardError
    :ng
  rescue Exception
    :ok
  end
}
assert_equal %q{c}, proc{
  begin
    begin
      raise "a"
    rescue
      raise "b"
    ensure
      raise "c"
    end
  rescue => e
    e.message
  end
}
assert_equal %q{33}, proc{
  def m a, b
    a + b
  end
  m(1, begin
         raise
       rescue
         2
       end) +
  m(10, begin
         raise
       rescue
         20
       ensure
         30
       end)
}
assert_equal %q{3}, proc{
  def m a, b
    a + b
  end
  m(begin
      raise
    rescue
      1
    end,
    begin
      raise
    rescue
      2
    end)
}
assert_equal %q{ok3}, proc{
  class E1 < Exception
  end
  
  def m
    yield
  end
  
  begin
    begin
      begin
        m{
          raise
        }
      rescue E1
        :ok2
      ensure
      end
    rescue
      :ok3
    ensure
    end
  rescue E1
    :ok
  ensure
  end
}
assert_equal %q{7}, proc{
  $i = 0
  def m
    iter{
      begin
        $i += 1
        begin
          $i += 2
          break
        ensure
          
        end
      ensure
        $i += 4
      end
      $i = 0
    }
  end
  
  def iter
    yield
  end
  m
  $i
}
assert_equal %q{10}, proc{
  $i = 0
  def m
    begin
      $i += 1
      begin
        $i += 2
        return
      ensure
        $i += 3
      end
    ensure
      $i += 4
    end
    p :end
  end
  m
  $i
}
assert_equal %q{1}, proc{
  begin
    1
  rescue
    2
  end
}
assert_equal %q{4}, proc{
  begin
    1
    begin
      2
    rescue
      3
    end
    4
  rescue
    5
  end
}
assert_equal %q{3}, proc{
  begin
    1
  rescue
    2
  else
    3
  end
}
assert_equal %q{2}, proc{
  begin
    1+1
  rescue
    2+2
  ensure
    3+3
  end
   }
assert_equal %q{2}, proc{
  begin
    1+1
  rescue
    2+2
  ensure
    3+3
  end
   }
assert_equal %q{6}, proc{
  begin
    1+1
  rescue
    2+2
  else
    3+3
  ensure
    4+4
  end
   }
assert_equal %q{12}, proc{
 begin
   1+1
   begin
     2+2
   rescue
     3+3
   else
     4+4
   end
 rescue
   5+5
 else
   6+6
 ensure
   7+7
 end
   }
assert_equal %q{ok}, proc{ # 
  proc{
    begin
      raise
      break
    rescue
      :ok
    end
  }.call
}
assert_equal %q{}, proc{
  proc do
    begin
      raise StandardError
      redo
    rescue StandardError
    end
  end.call
}

##
# assert_match /undefined method `foo\'/, proc{#`
#   STDERR.reopen(STDOUT)
#   class C
#     def inspect
#       bar {}
#     end
    
#     def bar
#       raise
#     ensure
#     end
#   end
#   C.new.foo
# }, "[ruby-dev:31407]"

# assert_equal 'nil', proc{
#   doit = false
#   exc = nil
#   t = Thread.new {
#     begin
#       doit = true
#       sleep 10
#     ensure
#       exc = $!
#     end
#   }
#   Thread.pass until doit
#   t.kill
#   t.join
#   exc.inspect
# }, '[ruby-dev:32608]'

# assert_equal 'exception class/object expected', proc{
#   class ZeroDivisionError
#     def self.new(message)
#       42
#     end
#   end
#   begin
#     1/0
#   rescue Exception => e
#     e.message
#   end
# }, '[ruby-core:24767]'

test_end