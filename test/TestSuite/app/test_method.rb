test_begin "test_method"

# regular argument
assert_equal '1',       proc{ def m() 1 end; m() }
assert_equal '1',       proc{ def m(a) a end; m(1) }
assert_equal '[1, 2]',  proc{ def m(a,b) [a, b] end; m(1,2) }
assert_equal '[1, 2, 3]', proc{ def m(a,b,c) [a, b, c] end; m(1,2,3) }
assert_equal 'wrong number of arguments (1 for 0)', proc{
  def m; end
  begin
    m(1)
  rescue => e
    e.message
  end
}

assert_equal 'wrong number of arguments (0 for 1)', proc{
  def m a; end
  begin
    m
  rescue => e
    e.message
  end
}

# default argument
assert_equal '1',       proc{ def m(x=1) x end; m() }
assert_equal '1',       proc{ def m(x=7) x end; m(1) }
assert_equal '1',       proc{ def m(a,x=1) x end; m(7) }
assert_equal '1',       proc{ def m(a,x=7) x end; m(7,1) }
assert_equal '1',       proc{ def m(a,b,x=1) x end; m(7,7) }
assert_equal '1',       proc{ def m(a,b,x=7) x end; m(7,7,1) }
assert_equal '1',       proc{ def m(a,x=1,y=1) x end; m(7) }
assert_equal '1',       proc{ def m(a,x=1,y=1) y end; m(7) }
assert_equal '1',       proc{ def m(a,x=7,y=1) x end; m(7,1) }
assert_equal '1',       proc{ def m(a,x=7,y=1) y end; m(7,1) }
assert_equal '1',       proc{ def m(a,x=7,y=7) x end; m(7,1,1) }
assert_equal '1',       proc{ def m(a,x=7,y=7) y end; m(7,1,1) }

# rest argument
assert_equal '[]',      proc{ def m(*a) a end; m().inspect }
assert_equal '[1]',     proc{ def m(*a) a end; m(1).inspect }
assert_equal '[1, 2]',  proc{ def m(*a) a end; m(1,2).inspect }
assert_equal '[]',      proc{ def m(x,*a) a end; m(7).inspect }
assert_equal '[1]',     proc{ def m(x,*a) a end; m(7,1).inspect }
assert_equal '[1, 2]',  proc{ def m(x,*a) a end; m(7,1,2).inspect }
assert_equal '[]',      proc{ def m(x,y,*a) a end; m(7,7).inspect }
assert_equal '[1]',     proc{ def m(x,y,*a) a end; m(7,7,1).inspect }
assert_equal '[1, 2]',  proc{ def m(x,y,*a) a end; m(7,7,1,2).inspect }
assert_equal '[]',      proc{ def m(x,y=7,*a) a end; m(7).inspect }
assert_equal '[]',      proc{ def m(x,y,z=7,*a) a end; m(7,7).inspect }
assert_equal '[]',      proc{ def m(x,y,z=7,*a) a end; m(7,7,7).inspect }
assert_equal '[]',      proc{ def m(x,y,z=7,zz=7,*a) a end; m(7,7,7).inspect }
assert_equal '[]',      proc{ def m(x,y,z=7,zz=7,*a) a end; m(7,7,7,7).inspect }
assert_equal '1',       proc{ def m(x,y,z=7,zz=1,*a) zz end; m(7,7,7).inspect }
assert_equal '1',       proc{ def m(x,y,z=7,zz=1,*a) zz end; m(7,7,7).inspect }
assert_equal '1',       proc{ def m(x,y,z=7,zz=7,*a) zz end; m(7,7,7,1).inspect }

# block argument
assert_equal 'Proc',    proc{ def m(&block) block end; m{}.class }
assert_equal 'nil',     proc{ def m(&block) block end; m().inspect }
assert_equal 'Proc',    proc{ def m(a,&block) block end; m(7){}.class }
assert_equal 'nil',     proc{ def m(a,&block) block end; m(7).inspect }
assert_equal '1',       proc{ def m(a,&block) a end; m(1){} }
assert_equal 'Proc',    proc{ def m(a,b=nil,&block) block end; m(7){}.class }
assert_equal 'nil',     proc{ def m(a,b=nil,&block) block end; m(7).inspect }
assert_equal 'Proc',    proc{ def m(a,b=nil,&block) block end; m(7,7){}.class }
assert_equal '1',       proc{ def m(a,b=nil,&block) b end; m(7,1){} }
assert_equal 'Proc',    proc{ def m(a,b=nil,*c,&block) block end; m(7){}.class }
assert_equal 'nil',     proc{ def m(a,b=nil,*c,&block) block end; m(7).inspect }
assert_equal '1',       proc{ def m(a,b=nil,*c,&block) a end; m(1).inspect }
assert_equal '1',       proc{ def m(a,b=1,*c,&block) b end; m(7).inspect }
assert_equal '1',       proc{ def m(a,b=7,*c,&block) b end; m(7,1).inspect }
assert_equal '[1]',     proc{ def m(a,b=7,*c,&block) c end; m(7,7,1).inspect }

# splat
assert_equal '1',       proc{ def m(a) a end; m(*[1]) }
assert_equal '1',       proc{ def m(x,a) a end; m(7,*[1]) }
assert_equal '1',       proc{ def m(x,y,a) a end; m(7,7,*[1]) }
assert_equal '1',       proc{ def m(a,b) a end; m(*[1,7]) }
assert_equal '1',       proc{ def m(a,b) b end; m(*[7,1]) }
assert_equal '1',       proc{ def m(x,a,b) b end; m(7,*[7,1]) }
assert_equal '1',       proc{ def m(x,y,a,b) b end; m(7,7,*[7,1]) }
assert_equal '1',       proc{ def m(a,b,c) a end; m(*[1,7,7]) }
assert_equal '1',       proc{ def m(a,b,c) b end; m(*[7,1,7]) }
assert_equal '1',       proc{ def m(a,b,c) c end; m(*[7,7,1]) }
assert_equal '1',       proc{ def m(x,a,b,c) a end; m(7,*[1,7,7]) }
assert_equal '1',       proc{ def m(x,y,a,b,c) a end; m(7,7,*[1,7,7]) }

# hash argument
assert_equal '1',       proc{ def m(h) h end; m(7=>1)[7] }
assert_equal '1',       proc{ def m(h) h end; m(7=>1).size }
assert_equal '1',       proc{ def m(h) h end; m(7=>1, 8=>7)[7] }
assert_equal '2',       proc{ def m(h) h end; m(7=>1, 8=>7).size }
assert_equal '1',       proc{ def m(h) h end; m(7=>1, 8=>7, 9=>7)[7] }
assert_equal '3',       proc{ def m(h) h end; m(7=>1, 8=>7, 9=>7).size }
assert_equal '1',       proc{ def m(x,h) h end; m(7, 7=>1)[7] }
assert_equal '1',       proc{ def m(x,h) h end; m(7, 7=>1, 8=>7)[7] }
assert_equal '1',       proc{ def m(x,h) h end; m(7, 7=>1, 8=>7, 9=>7)[7] }
assert_equal '1',       proc{ def m(x,y,h) h end; m(7,7, 7=>1)[7] }
assert_equal '1',       proc{ def m(x,y,h) h end; m(7,7, 7=>1, 8=>7)[7] }
assert_equal '1',       proc{ def m(x,y,h) h end; m(7,7, 7=>1, 8=>7, 9=>7)[7] }

# block argument
assert_equal '1',       proc{ def m(&block) mm(&block) end
                           def mm() yield 1 end
                           m {|a| a } }
assert_equal '1',       proc{ def m(x,&block) mm(x,&block) end
                           def mm(x) yield 1 end
                           m(7) {|a| a } }
assert_equal '1',       proc{ def m(x,y,&block) mm(x,y,&block) end
                           def mm(x,y) yield 1 end
                           m(7,7) {|a| a } }

# recursive call
assert_equal '1',       proc{ def m(n) n == 0 ? 1 : m(n-1) end; m(5) }

# instance method
assert_equal '1',       proc{ class C; def m() 1 end end;  C.new.m }
assert_equal '1',       proc{ class C; def m(a) a end end;  C.new.m(1) }
assert_equal '1',       proc{ class C; def m(a = 1) a end end;  C.new.m }
assert_equal '[1]',     proc{ class C; def m(*a) a end end;  C.new.m(1).inspect }
assert_equal '1',       proc{  class C
                              def m() mm() end
                              def mm() 1 end
                            end
                            C.new.m }

# singleton method (const)
assert_equal '1',       proc{ class C; def C.m() 1 end end;  C.m }
assert_equal '1',       proc{ class C; def C.m(a) a end end;  C.m(1) }
assert_equal '1',       proc{ class C; def C.m(a = 1) a end end;  C.m }
assert_equal '[1]',     proc{ class C; def C.m(*a) a end end;  C.m(1).inspect }
assert_equal '1',       proc{ class C; end; def C.m() 1 end;  C.m }
assert_equal '1',       proc{ class C; end; def C.m(a) a end;  C.m(1) }
assert_equal '1',       proc{ class C; end; def C.m(a = 1) a end;  C.m }
assert_equal '[1]',     proc{ class C; end; def C.m(*a) a end;  C.m(1).inspect }
assert_equal '1',       proc{ class C; def m() 7 end end; def C.m() 1 end;  C.m }
assert_equal '1',       proc{  class C
                              def C.m() mm() end
                              def C.mm() 1 end
                            end
                            C.m }

# singleton method (lvar)
assert_equal '1',       proc{ obj = Object.new; def obj.m() 1 end;  obj.m }
assert_equal '1',       proc{ obj = Object.new; def obj.m(a) a end;  obj.m(1) }
assert_equal '1',       proc{ obj = Object.new; def obj.m(a=1) a end;  obj.m }
assert_equal '[1]',     proc{ obj = Object.new; def obj.m(*a) a end;  obj.m(1)}
assert_equal '1',       proc{ class C; def m() 7 end; end
                           obj = C.new
                           def obj.m() 1 end
                           obj.m }

# inheritance
assert_equal '1',       proc{ class A; def m(a) a end end
                           class B < A; end
                           B.new.m(1) }
assert_equal '1',       proc{ class A; end
                           class B < A; def m(a) a end end
                           B.new.m(1) }
# assert_equal '1',       proc{ class A; def m(a) a end end
#                            class B < A; end
#                            class C < B; end
#                            C.new.m(1) }

# include
assert_equal '1',       proc{ class A; def m(a) a end end
                           module M; end
                           class B < A; include M; end
                           B.new.m(1) }
assert_equal '1',       proc{ class A; end
                           module M; def m(a) a end end
                           class B < A; include M; end
                           B.new.m(1) }

# alias
# assert_equal '1',       proc{  def a() 1 end
#                             alias m a
#                             m() }
assert_equal '1',       proc{  class C
                              def a() 1 end
                              alias m a
                            end
                            C.new.m }
assert_equal '1',       proc{  class C
                              def a() 1 end
                              alias :m a
                            end
                            C.new.m }
assert_equal '1',       proc{  class C
                              def a() 1 end
                              alias m :a
                            end
                            C.new.m }
assert_equal '1',       proc{  class C
                              def a() 1 end
                              alias :m :a
                            end
                            C.new.m }
assert_equal '1',       proc{  class C
                              def a() 1 end
                              alias m a
                              undef a
                            end
                            C.new.m }

# undef
assert_equal '1',       proc{  class C
                              def m() end
                              undef m
                            end
                            begin C.new.m; rescue NoMethodError; 1 end }
# assert_equal '1',       proc{  class A
#                               def m() end
#                             end
#                             class C < A
#                               def m() end
#                               undef m
#                             end
#                             begin C.new.m; rescue NoMethodError; 1 end }
assert_equal '1',       proc{  class A; def a() end end   # [yarv-dev:999]
                            class B < A
                              def b() end
                              undef a, b
                            end
                            begin B.new.a; rescue NoMethodError; 1 end }
# assert_equal '1',       proc{  class A; def a() end end   # [yarv-dev:999]
#                             class B < A
#                               def b() end
#                               undef a, b
#                             end
#                             begin B.new.b; rescue NoMethodError; 1 end }

# assert_equal '3', proc{
#   def m1
#     1
#   end
#   alias m2 m1
#   alias :"#{'m3'}" m1
#   m1 + m2 + m3
# }, '[ruby-dev:32308]'
assert_equal '1', proc{
  def foobar
  end
  undef :"foo#{:bar}"
  1
}, '[ruby-dev:32308]'
# assert_equal '1', proc{
#   def foobar
#     1
#   end
#   alias :"bar#{:baz}" :"foo#{:bar}"
#   barbaz
# }, '[ruby-dev:32308]'

# private
assert_equal '1',       proc{  class C
                              def m() mm() end
                              def mm() 1 end
                              private :mm
                            end
                            C.new.m }
assert_equal '1',       proc{  class C
                              def m() 7 end
                              private :m
                            end
                            begin C.m; rescue NoMethodError; 1 end }
assert_equal '1',       proc{  class C
                              def C.m() mm() end
                              def C.mm() 1 end
                              private_class_method :mm
                            end
                            C.m }
assert_equal '1',       proc{  class C
                              def C.m() 7 end
                              private_class_method :m
                            end
                            begin C.m; rescue NoMethodError; 1 end }
assert_equal '1',       proc{  class C; def m() 1 end end
                            C.new.m   # cache
                            class C
                              alias mm m; private :mm
                            end
                            C.new.m
                            begin C.new.mm; 7; rescue NoMethodError; 1 end }

# nested method
assert_equal '1',       proc{  class C
                              def m
                                def mm() 1 end
                              end
                            end
                            C.new.m
                            C.new.mm }
# assert_equal '1',       proc{  class C
#                               def m
#                                 def mm() 1 end
#                               end
#                             end
#                             instance_eval "C.new.m; C.new.mm" }

# method_missing
# assert_equal ':m',      proc{  class C5
#                               def method_missing(mid, *args) mid end
#                             end
#                             C5.new.m.inspect }
# assert_equal ':mm',     proc{  class C5
#                               def method_missing(mid, *args) mid end
#                             end
#                             C5.new.mm.inspect }
# assert_equal '[1, 2]',  proc{  class C5
#                               def method_missing(mid, *args) args end
#                             end
#                             C5.new.m(1,2).inspect }
# assert_equal '1',       proc{  class C5
#                               def method_missing(mid, *args) yield 1 end
#                             end
#                             C5.new.m {|a| a } }
# assert_equal 'nil',     proc{  class C5
#                               def method_missing(mid, *args, &block) block end
#                             end
#                             C5.new.m.inspect }

# send
assert_equal '1',       proc{  class C; def m() 1 end end;
                            C.new.__send__(:m) }
assert_equal '1',       proc{  class C; def m() 1 end end;
                            C.new.send(:m) }
assert_equal '1',       proc{  class C; def m(a) a end end;
                            C.new.send(:m,1) }
assert_equal '1',       proc{  class C; def m(a,b) a end end;
                            C.new.send(:m,1,7) }
assert_equal '1',       proc{  class C; def m(x,a=1) a end end;
                            C.new.send(:m,7) }
assert_equal '1',       proc{  class C; def m(x,a=7) a end end;
                            C.new.send(:m,7,1) }
assert_equal '[1, 2]',  proc{  class C; def m(*a) a end end;
                            C.new.send(:m,1,2).inspect }
assert_equal '1',       proc{  class C; def m() 7 end; private :m end
                            begin C.new.public_send(:m); rescue NoMethodError; 1 end }
assert_equal '1',       proc{  class C; def m() 1 end; private :m end
                            C.new.send(:m) }

# with block
# assert_equal '[[:ok1, :foo], [:ok2, :foo, :bar]]',
# proc{
#   class C
#     def [](a)
#       $ary << [yield, a]
#     end
#     def []=(a, b)
#       $ary << [yield, a, b]
#     end
#   end

#   $ary = []
#   C.new[:foo, &lambda{:ok1}]
#   C.new[:foo, &lambda{:ok2}] = :bar
#   $ary
# }

# with
# assert_equal '[:ok1, [:ok2, 11]]', proc{
#   class C
#     def []
#       $ary << :ok1
#       10
#     end
#     def []=(a)
#       $ary << [:ok2, a]
#     end
#   end
#   $ary = []
#   C.new[]+=1
#   $ary
# }

# splat and block arguments
assert_equal %q{[[[:x, :y, :z], NilClass], [[1, :x, :y, :z], NilClass], [[1, 2, :x, :y, :z], NilClass], [[:obj], NilClass], [[1, :obj], NilClass], [[1, 2, :obj], NilClass], [[], Proc], [[1], Proc], [[1, 2], Proc], [[], Proc], [[1], Proc], [[1, 2], Proc], [[:x, :y, :z], Proc], [[1, :x, :y, :z], Proc], [[1, 2, :x, :y, :z], Proc]]}, proc{
def m(*args, &b)
  $result << [args, b.class]
end
$result = []
ary = [:x, :y, :z]
obj = :obj
b = Proc.new{}

m(*ary)
m(1,*ary)
m(1,2,*ary)
m(*obj)
m(1,*obj)
m(1,2,*obj)
m(){}
m(1){}
m(1,2){}
m(&b)
m(1,&b)
m(1,2,&b)
m(*ary,&b)
m(1,*ary,&b)
m(1,2,*ary,&b)
$result
}

# post test
assert_equal %q{[1, 2, :o1, :o2, [], 3, 4, NilClass, nil, nil]}, proc{
def m(m1, m2, o1=:o1, o2=:o2, *r, p1, p2, &b)
  x, y = :x, :y if $foo
  [m1, m2, o1, o2, r, p1, p2, b.class, x, y]
end
; m(1, 2, 3, 4)}

assert_equal %q{[1, 2, 3, :o2, [], 4, 5, NilClass, nil, nil]}, proc{
def m(m1, m2, o1=:o1, o2=:o2, *r, p1, p2, &b)
  x, y = :x, :y if $foo
  [m1, m2, o1, o2, r, p1, p2, b.class, x, y]
end
; m(1, 2, 3, 4, 5)}

assert_equal %q{[1, 2, 3, 4, [], 5, 6, NilClass, nil, nil]}, proc{
def m(m1, m2, o1=:o1, o2=:o2, *r, p1, p2, &b)
  x, y = :x, :y if $foo
  [m1, m2, o1, o2, r, p1, p2, b.class, x, y]
end
; m(1, 2, 3, 4, 5, 6)}

assert_equal %q{[1, 2, 3, 4, [5], 6, 7, NilClass, nil, nil]}, proc{
def m(m1, m2, o1=:o1, o2=:o2, *r, p1, p2, &b)
  x, y = :x, :y if $foo
  [m1, m2, o1, o2, r, p1, p2, b.class, x, y]
end
; m(1, 2, 3, 4, 5, 6, 7)}

assert_equal %q{[1, 2, 3, 4, [5, 6], 7, 8, NilClass, nil, nil]}, proc{
def m(m1, m2, o1=:o1, o2=:o2, *r, p1, p2, &b)
  x, y = :x, :y if $foo
  [m1, m2, o1, o2, r, p1, p2, b.class, x, y]
end
; m(1, 2, 3, 4, 5, 6, 7, 8)}

assert_equal %q{[1, 2, 3, 4, [5, 6, 7], 8, 9, NilClass, nil, nil]}, proc{
def m(m1, m2, o1=:o1, o2=:o2, *r, p1, p2, &b)
  x, y = :x, :y if $foo
  [m1, m2, o1, o2, r, p1, p2, b.class, x, y]
end
; m(1, 2, 3, 4, 5, 6, 7, 8, 9)}

assert_equal %q{[1, 2, 3, 4, [5, 6, 7, 8], 9, 10, NilClass, nil, nil]}, proc{
def m(m1, m2, o1=:o1, o2=:o2, *r, p1, p2, &b)
  x, y = :x, :y if $foo
  [m1, m2, o1, o2, r, p1, p2, b.class, x, y]
end
; m(1, 2, 3, 4, 5, 6, 7, 8, 9, 10)}

assert_equal %q{[1, 2, 3, 4, [5, 6, 7, 8, 9], 10, 11, NilClass, nil, nil]}, proc{
def m(m1, m2, o1=:o1, o2=:o2, *r, p1, p2, &b)
  x, y = :x, :y if $foo
  [m1, m2, o1, o2, r, p1, p2, b.class, x, y]
end
; m(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11)}

assert_equal %q{[1, 2, :o1, :o2, [], 3, 4, Proc, nil, nil]}, proc{
def m(m1, m2, o1=:o1, o2=:o2, *r, p1, p2, &b)
  x, y = :x, :y if $foo
  [m1, m2, o1, o2, r, p1, p2, b.class, x, y]
end
; m(1, 2, 3, 4){}}

assert_equal %q{[1, 2, 3, :o2, [], 4, 5, Proc, nil, nil]}, proc{
def m(m1, m2, o1=:o1, o2=:o2, *r, p1, p2, &b)
  x, y = :x, :y if $foo
  [m1, m2, o1, o2, r, p1, p2, b.class, x, y]
end
; m(1, 2, 3, 4, 5){}}

assert_equal %q{[1, 2, 3, 4, [], 5, 6, Proc, nil, nil]}, proc{
def m(m1, m2, o1=:o1, o2=:o2, *r, p1, p2, &b)
  x, y = :x, :y if $foo
  [m1, m2, o1, o2, r, p1, p2, b.class, x, y]
end
; m(1, 2, 3, 4, 5, 6){}}

assert_equal %q{[1, 2, 3, 4, [5], 6, 7, Proc, nil, nil]}, proc{
def m(m1, m2, o1=:o1, o2=:o2, *r, p1, p2, &b)
  x, y = :x, :y if $foo
  [m1, m2, o1, o2, r, p1, p2, b.class, x, y]
end
; m(1, 2, 3, 4, 5, 6, 7){}}

assert_equal %q{[1, 2, 3, 4, [5, 6], 7, 8, Proc, nil, nil]}, proc{
def m(m1, m2, o1=:o1, o2=:o2, *r, p1, p2, &b)
  x, y = :x, :y if $foo
  [m1, m2, o1, o2, r, p1, p2, b.class, x, y]
end
; m(1, 2, 3, 4, 5, 6, 7, 8){}}

assert_equal %q{[1, 2, 3, 4, [5, 6, 7], 8, 9, Proc, nil, nil]}, proc{
def m(m1, m2, o1=:o1, o2=:o2, *r, p1, p2, &b)
  x, y = :x, :y if $foo
  [m1, m2, o1, o2, r, p1, p2, b.class, x, y]
end
; m(1, 2, 3, 4, 5, 6, 7, 8, 9){}}

assert_equal %q{[1, 2, 3, 4, [5, 6, 7, 8], 9, 10, Proc, nil, nil]}, proc{
def m(m1, m2, o1=:o1, o2=:o2, *r, p1, p2, &b)
  x, y = :x, :y if $foo
  [m1, m2, o1, o2, r, p1, p2, b.class, x, y]
end
; m(1, 2, 3, 4, 5, 6, 7, 8, 9, 10){}}

assert_equal %q{[1, 2, 3, 4, [5, 6, 7, 8, 9], 10, 11, Proc, nil, nil]}, proc{
def m(m1, m2, o1=:o1, o2=:o2, *r, p1, p2, &b)
  x, y = :x, :y if $foo
  [m1, m2, o1, o2, r, p1, p2, b.class, x, y]
end
; m(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11){}}

assert_equal %q{[1, 2, :o1, :o2, [], 3, 4, nil, nil]}, proc{
def m(m1, m2, o1=:o1, o2=:o2, *r, p1, p2)
  x, y = :x, :y if $foo
  [m1, m2, o1, o2, r, p1, p2, x, y]
end
; m(1, 2, 3, 4)}

assert_equal %q{[1, 2, 3, :o2, [], 4, 5, nil, nil]}, proc{
def m(m1, m2, o1=:o1, o2=:o2, *r, p1, p2)
  x, y = :x, :y if $foo
  [m1, m2, o1, o2, r, p1, p2, x, y]
end
; m(1, 2, 3, 4, 5)}

assert_equal %q{[1, 2, 3, 4, [], 5, 6, nil, nil]}, proc{
def m(m1, m2, o1=:o1, o2=:o2, *r, p1, p2)
  x, y = :x, :y if $foo
  [m1, m2, o1, o2, r, p1, p2, x, y]
end
; m(1, 2, 3, 4, 5, 6)}


#
# super
#
=begin
# below programs are generated by this program:

BASE = <<EOS__
class C0; def m *args; [:C0_m, args]; end; end
class C1 < C0; <TEST>; super; end; end
EOS__

tests = {
%q{
  def m
} => %q{
  C1.new.m
},
#
%q{
  def m a
} => %q{
  C1.new.m 1
},
%q{
  def m a
    a = :a
} => %q{
  C1.new.m 1
},
#
%q{
  def m a, o=:o
} => %q{
  C1.new.m 1
  C1.new.m 1, 2
},
%q{
  def m a, o=:o
    a = :a
} => %q{
  C1.new.m 1
  C1.new.m 1, 2
},
%q{
  def m a, o=:o
    o = :x
} => %q{
  C1.new.m 1
  C1.new.m 1, 2
},
#
%q{
  def m a, *r
} => %q{
  C1.new.m 1
  C1.new.m 1, 2
  C1.new.m 1, 2, 3
},
%q{
  def m a, *r
    r = [:x, :y]
} => %q{
  C1.new.m 1
  C1.new.m 1, 2
  C1.new.m 1, 2, 3
},
#
%q{
  def m a, o=:o, *r
} => %q{
  C1.new.m 1
  C1.new.m 1, 2
  C1.new.m 1, 2, 3
  C1.new.m 1, 2, 3, 4
},
#
%q{
  def m a, o=:o, *r, &b
} => %q{
  C1.new.m 1
  C1.new.m 1, 2
  C1.new.m 1, 2, 3
  C1.new.m 1, 2, 3, 4
  C1.new.m(1){}
  C1.new.m(1, 2){}
  C1.new.m(1, 2, 3){}
  C1.new.m(1, 2, 3, 4){}
},
#
"def m(m1, m2, o1=:o1, o2=:o2, p1, p2)" =>
%q{
C1.new.m(1,2,3,4)
C1.new.m(1,2,3,4,5)
C1.new.m(1,2,3,4,5,6)
},
#
"def m(m1, m2, *r, p1, p2)" =>
%q{
C1.new.m(1,2,3,4)
C1.new.m(1,2,3,4,5)
C1.new.m(1,2,3,4,5,6)
C1.new.m(1,2,3,4,5,6,7)
C1.new.m(1,2,3,4,5,6,7,8)
},
#
"def m(m1, m2, o1=:o1, o2=:o2, *r, p1, p2)" =>
%q{
C1.new.m(1,2,3,4)
C1.new.m(1,2,3,4,5)
C1.new.m(1,2,3,4,5,6)
C1.new.m(1,2,3,4,5,6,7)
C1.new.m(1,2,3,4,5,6,7,8)
C1.new.m(1,2,3,4,5,6,7,8,9)
},

###
}


tests.each{|setup, methods| setup = setup.dup; setup.strip!
  setup = BASE.gsub(/<TEST>/){setup}
  methods.split(/\n/).each{|m| m = m.dup; m.strip!
    next if m.empty?
    expr = "#{setup}; #{m}"
    result = eval(expr)
    puts "assert_equal %q{#{result.inspect}}, proc{\n#{expr}}"
    puts
  }
}

=end

# assert_equal %q{[:C0_m, [1, 2, :o1, :o2, 3, 4]]}, proc{
# class C0; def m *args; [:C0_m, args]; end; end
# class C1 < C0; def m(m1, m2, o1=:o1, o2=:o2, p1, p2); super; end; end
# ; C1.new.m(1,2,3,4)}

# assert_equal %q{[:C0_m, [1, 2, 3, :o2, 4, 5]]}, proc{
# class C0; def m *args; [:C0_m, args]; end; end
# class C1 < C0; def m(m1, m2, o1=:o1, o2=:o2, p1, p2); super; end; end
# ; C1.new.m(1,2,3,4,5)}

# assert_equal %q{[:C0_m, [1, 2, 3, 4, 5, 6]]}, proc{
# class C0; def m *args; [:C0_m, args]; end; end
# class C1 < C0; def m(m1, m2, o1=:o1, o2=:o2, p1, p2); super; end; end
# ; C1.new.m(1,2,3,4,5,6)}

# assert_equal %q{[:C0_m, [1, :o]]}, proc{
# class C0; def m *args; [:C0_m, args]; end; end
# class C1 < C0; def m a, o=:o, *r; super; end; end
# ; C1.new.m 1}

# assert_equal %q{[:C0_m, [1, 2]]}, proc{
# class C0; def m *args; [:C0_m, args]; end; end
# class C1 < C0; def m a, o=:o, *r; super; end; end
# ; C1.new.m 1, 2}

# assert_equal %q{[:C0_m, [1, 2, 3]]}, proc{
# class C0; def m *args; [:C0_m, args]; end; end
# class C1 < C0; def m a, o=:o, *r; super; end; end
# ; C1.new.m 1, 2, 3}

# assert_equal %q{[:C0_m, [1, 2, 3, 4]]}, proc{
# class C0; def m *args; [:C0_m, args]; end; end
# class C1 < C0; def m a, o=:o, *r; super; end; end
# ; C1.new.m 1, 2, 3, 4}

# assert_equal %q{[:C0_m, [:a]]}, proc{
# class C0; def m *args; [:C0_m, args]; end; end
# class C1 < C0; def m a
#     a = :a; super; end; end
# ; C1.new.m 1}

# assert_equal %q{[:C0_m, [1, 2, 3, 4]]}, proc{
# class C0; def m *args; [:C0_m, args]; end; end
# class C1 < C0; def m(m1, m2, *r, p1, p2); super; end; end
# ; C1.new.m(1,2,3,4)}

# assert_equal %q{[:C0_m, [1, 2, 3, 4, 5]]}, proc{
# class C0; def m *args; [:C0_m, args]; end; end
# class C1 < C0; def m(m1, m2, *r, p1, p2); super; end; end
# ; C1.new.m(1,2,3,4,5)}

# assert_equal %q{[:C0_m, [1, 2, 3, 4, 5, 6]]}, proc{
# class C0; def m *args; [:C0_m, args]; end; end
# class C1 < C0; def m(m1, m2, *r, p1, p2); super; end; end
# ; C1.new.m(1,2,3,4,5,6)}

# assert_equal %q{[:C0_m, [1, 2, 3, 4, 5, 6, 7]]}, proc{
# class C0; def m *args; [:C0_m, args]; end; end
# class C1 < C0; def m(m1, m2, *r, p1, p2); super; end; end
# ; C1.new.m(1,2,3,4,5,6,7)}

# assert_equal %q{[:C0_m, [1, 2, 3, 4, 5, 6, 7, 8]]}, proc{
# class C0; def m *args; [:C0_m, args]; end; end
# class C1 < C0; def m(m1, m2, *r, p1, p2); super; end; end
# ; C1.new.m(1,2,3,4,5,6,7,8)}

# assert_equal %q{[:C0_m, [1, :o]]}, proc{
# class C0; def m *args; [:C0_m, args]; end; end
# class C1 < C0; def m a, o=:o, *r, &b; super; end; end
# ; C1.new.m 1}

# assert_equal %q{[:C0_m, [1, 2]]}, proc{
# class C0; def m *args; [:C0_m, args]; end; end
# class C1 < C0; def m a, o=:o, *r, &b; super; end; end
# ; C1.new.m 1, 2}

# assert_equal %q{[:C0_m, [1, 2, 3]]}, proc{
# class C0; def m *args; [:C0_m, args]; end; end
# class C1 < C0; def m a, o=:o, *r, &b; super; end; end
# ; C1.new.m 1, 2, 3}

# assert_equal %q{[:C0_m, [1, 2, 3, 4]]}, proc{
# class C0; def m *args; [:C0_m, args]; end; end
# class C1 < C0; def m a, o=:o, *r, &b; super; end; end
# ; C1.new.m 1, 2, 3, 4}

# assert_equal %q{[:C0_m, [1, :o]]}, proc{
# class C0; def m *args; [:C0_m, args]; end; end
# class C1 < C0; def m a, o=:o, *r, &b; super; end; end
# ; C1.new.m(1){}}

# assert_equal %q{[:C0_m, [1, 2]]}, proc{
# class C0; def m *args; [:C0_m, args]; end; end
# class C1 < C0; def m a, o=:o, *r, &b; super; end; end
# ; C1.new.m(1, 2){}}

# assert_equal %q{[:C0_m, [1, 2, 3]]}, proc{
# class C0; def m *args; [:C0_m, args]; end; end
# class C1 < C0; def m a, o=:o, *r, &b; super; end; end
# ; C1.new.m(1, 2, 3){}}

# assert_equal %q{[:C0_m, [1, 2, 3, 4]]}, proc{
# class C0; def m *args; [:C0_m, args]; end; end
# class C1 < C0; def m a, o=:o, *r, &b; super; end; end
# ; C1.new.m(1, 2, 3, 4){}}

# assert_equal %q{[:C0_m, [1, :x]]}, proc{
# class C0; def m *args; [:C0_m, args]; end; end
# class C1 < C0; def m a, o=:o
#     o = :x; super; end; end
# ; C1.new.m 1}

# assert_equal %q{[:C0_m, [1, :x]]}, proc{
# class C0; def m *args; [:C0_m, args]; end; end
# class C1 < C0; def m a, o=:o
#     o = :x; super; end; end
# ; C1.new.m 1, 2}

# assert_equal %q{[:C0_m, [:a, :o]]}, proc{
# class C0; def m *args; [:C0_m, args]; end; end
# class C1 < C0; def m a, o=:o
#     a = :a; super; end; end
# ; C1.new.m 1}

# assert_equal %q{[:C0_m, [:a, 2]]}, proc{
# class C0; def m *args; [:C0_m, args]; end; end
# class C1 < C0; def m a, o=:o
#     a = :a; super; end; end
# ; C1.new.m 1, 2}

# assert_equal %q{[:C0_m, [1]]}, proc{
# class C0; def m *args; [:C0_m, args]; end; end
# class C1 < C0; def m a; super; end; end
# ; C1.new.m 1}

# assert_equal %q{[:C0_m, [1, :x, :y]]}, proc{
# class C0; def m *args; [:C0_m, args]; end; end
# class C1 < C0; def m a, *r
#     r = [:x, :y]; super; end; end
# ; C1.new.m 1}

# assert_equal %q{[:C0_m, [1, :x, :y]]}, proc{
# class C0; def m *args; [:C0_m, args]; end; end
# class C1 < C0; def m a, *r
#     r = [:x, :y]; super; end; end
# ; C1.new.m 1, 2}

# assert_equal %q{[:C0_m, [1, :x, :y]]}, proc{
# class C0; def m *args; [:C0_m, args]; end; end
# class C1 < C0; def m a, *r
#     r = [:x, :y]; super; end; end
# ; C1.new.m 1, 2, 3}

# assert_equal %q{[:C0_m, [1, 2, :o1, :o2, 3, 4]]}, proc{
# class C0; def m *args; [:C0_m, args]; end; end
# class C1 < C0; def m(m1, m2, o1=:o1, o2=:o2, *r, p1, p2); super; end; end
# ; C1.new.m(1,2,3,4)}

# assert_equal %q{[:C0_m, [1, 2, 3, :o2, 4, 5]]}, proc{
# class C0; def m *args; [:C0_m, args]; end; end
# class C1 < C0; def m(m1, m2, o1=:o1, o2=:o2, *r, p1, p2); super; end; end
# ; C1.new.m(1,2,3,4,5)}

# assert_equal %q{[:C0_m, [1, 2, 3, 4, 5, 6]]}, proc{
# class C0; def m *args; [:C0_m, args]; end; end
# class C1 < C0; def m(m1, m2, o1=:o1, o2=:o2, *r, p1, p2); super; end; end
# ; C1.new.m(1,2,3,4,5,6)}

# assert_equal %q{[:C0_m, [1, 2, 3, 4, 5, 6, 7]]}, proc{
# class C0; def m *args; [:C0_m, args]; end; end
# class C1 < C0; def m(m1, m2, o1=:o1, o2=:o2, *r, p1, p2); super; end; end
# ; C1.new.m(1,2,3,4,5,6,7)}

# assert_equal %q{[:C0_m, [1, 2, 3, 4, 5, 6, 7, 8]]}, proc{
# class C0; def m *args; [:C0_m, args]; end; end
# class C1 < C0; def m(m1, m2, o1=:o1, o2=:o2, *r, p1, p2); super; end; end
# ; C1.new.m(1,2,3,4,5,6,7,8)}

# assert_equal %q{[:C0_m, [1, 2, 3, 4, 5, 6, 7, 8, 9]]}, proc{
# class C0; def m *args; [:C0_m, args]; end; end
# class C1 < C0; def m(m1, m2, o1=:o1, o2=:o2, *r, p1, p2); super; end; end
# ; C1.new.m(1,2,3,4,5,6,7,8,9)}

# assert_equal %q{[:C0_m, [1]]}, proc{
# class C0; def m *args; [:C0_m, args]; end; end
# class C1 < C0; def m a, *r; super; end; end
# ; C1.new.m 1}

# assert_equal %q{[:C0_m, [1, 2]]}, proc{
# class C0; def m *args; [:C0_m, args]; end; end
# class C1 < C0; def m a, *r; super; end; end
# ; C1.new.m 1, 2}

# assert_equal %q{[:C0_m, [1, 2, 3]]}, proc{
# class C0; def m *args; [:C0_m, args]; end; end
# class C1 < C0; def m a, *r; super; end; end
# ; C1.new.m 1, 2, 3}

# assert_equal %q{[:C0_m, []]}, proc{
# class C0; def m *args; [:C0_m, args]; end; end
# class C1 < C0; def m; super; end; end
# ; C1.new.m}

# assert_equal %q{[:C0_m, [1, :o]]}, proc{
# class C0; def m *args; [:C0_m, args]; end; end
# class C1 < C0; def m a, o=:o; super; end; end
# ; C1.new.m 1}

# assert_equal %q{[:C0_m, [1, 2]]}, proc{
# class C0; def m *args; [:C0_m, args]; end; end
# class C1 < C0; def m a, o=:o; super; end; end
# ; C1.new.m 1, 2}

# assert_equal %q{[:ok, :ok, :ok, :ok, :ok, :ok, :ng, :ng]}, proc{
#   $ans = []
#   class Foo
#     def m
#     end
#   end

#   c1 = c2 = nil

#   lambda{
#     $SAFE = 4
#     c1 = Class.new{
#       def m
#       end
#     }
#     c2 = Class.new(Foo){
#       alias mm m
#     }
#   }.call

#   def test
#     begin
#       yield
#     rescue SecurityError
#       $ans << :ok
#     else
#       $ans << :ng
#     end
#   end

#   o1 = c1.new
#   o2 = c2.new
  
#   test{o1.m}
#   test{o2.mm}
#   test{o1.send :m}
#   test{o2.send :mm}
#   test{o1.public_send :m}
#   test{o2.public_send :mm}
#   test{o1.method(:m).call}
#   test{o2.method(:mm).call}
#   $ans
# }

assert_equal 'ok', proc{
  class C
    def x=(n)
    end
    def m
      self.x = :ok
    end
  end
  C.new.m
}

assert_equal 'ok', proc{
  proc{
    $SAFE = 1
    class C
      def m
        :ok
      end
    end
  }.call
  C.new.m
}, '[ruby-core:11998]'

assert_equal 'ok', proc{
  proc{
    $SAFE = 2
    class C
      def m
        :ok
      end
    end
  }.call
  C.new.m
}, '[ruby-core:11998]'

# assert_equal 'ok', proc{
#   proc{
#     $SAFE = 3
#     class C
#       def m
#         :ng
#       end
#     end
#   }.call
#   begin
#     C.new.m
#   rescue SecurityError
#     :ok
#   end
# }, '[ruby-core:11998]'

# assert_equal 'ok', proc{
#   class B
#     def m() :fail end
#   end
#   class C < B
#     undef m
#     begin
#       remove_method :m
#     rescue NameError
#     end
#   end
#   begin
#     C.new.m
#   rescue NameError
#     :ok
#   end
# }, '[ruby-dev:31816], [ruby-dev:31817]'

# assert_normal_exit proc{
#   begin
#     Process.setrlimit(Process::RLIMIT_STACK, 4_202_496)
#     # FreeBSD fails this less than 4M + 8K bytes.
#   rescue Exception
#     exit
#   end
#   class C
#     attr "a" * (10*1024*1024)
#   end
# }, '[ruby-dev:31818]'

assert_equal 'ok', proc{
  class Module
    def define_method2(name, &block)
      define_method(name, &block)
    end
  end
  class C
    define_method2(:m) {|x, y| :fail }
  end
  begin
    C.new.m([1,2])
  rescue ArgumentError
    :ok
  end
}

# assert_not_match /method_missing/, proc{
#   STDERR.reopen(STDOUT)
#   variable_or_mehtod_not_exist
# }

# assert_equal '[false, false, false, false, true, true]', proc{
#   class C
#     define_method(:foo) {
#       block_given?
#     }
#   end

#   C.new.foo {}

#   class D
#     def foo
#       D.module_eval{
#         define_method(:m1){
#           block_given?
#         }
#       }
#     end
#     def bar
#       D.module_eval{
#         define_method(:m2){
#           block_given?
#         }
#       }
#     end
#   end

#   D.new.foo
#   D.new.bar{}
#   [C.new.foo, C.new.foo{}, D.new.m1, D.new.m1{}, D.new.m2, D.new.m2{}]
# }, '[ruby-core:14813]'

assert_equal 'ok', proc{
  class Foo
    define_method(:foo) do |&b|
      b.call
    end
  end
  Foo.new.foo do
    break :ok
  end
}, '[ruby-dev:36028]'

# assert_equal '[1, 2, [3, 4]]', proc{
#   def regular(a, b, *c)
#     [a, b, c]
#   end
#   regular(*[], 1, *[], *[2, 3], *[], 4) 
# }, '[ruby-core:19413]'

# assert_equal '[1, [:foo, 3, 4, :foo]]', proc{
#   def regular(a, *b)
#     [a, b]
#   end
#   a = b = [:foo]
#   regular(1, *a, *[3, 4], *b)
# }

# assert_equal '["B", "A"]', proc{
#   class A
#     def m
#       proc{ A }
#     end
#   end

#   class B < A
#     define_method(:m) do    
#       ['B', super()]
#     end
#   end

#   class C < B
#   end

#   C.new.m
# }

# assert_equal 'ok', proc{
#   module Foo
#     def foo
#       begin
#         super
#       rescue NoMethodError
#         :ok
#       end
#     end
#     module_function :foo
#   end
#   Foo.foo
# }, '[ruby-dev:37587]'

# assert_equal 'Object#foo', proc{
#   class Object
#     def self.foo
#       "Object.foo"
#     end
#     def foo
#       "Object#foo"
#     end
#   end

#   module Foo
#     def foo
#       begin
#         super
#       rescue NoMethodError
#         :ok
#       end
#     end
#     module_function :foo
#   end
#   Foo.foo
# }, '[ruby-dev:37587]'

# assert_normal_exit proc{
#   class BasicObject
#     remove_method :method_missing
#   end
#   begin
#     "a".lalala!
#   rescue NoMethodError => e
#     e.message == "undefined method `lalala!' for \"a\":String" ? :ok : :ng
#   end
# }, '[ruby-core:22298]'

assert_equal 'ok', proc{
  "hello"[0] ||= "H"
  "ok"
}

assert_equal 'ok', proc{
  "hello"[0, 1] ||= "H"
  "ok"
}

# assert_equal 'ok', proc{
#   class C
#     define_method(:foo) do
#       C.class_eval { remove_method(:foo) }
#       super()
#     end
#   end
#   begin
#     C.new.foo
#   rescue NoMethodError
#     proc{ ok }
#   end
# }
# assert_equal 'ok', proc{
#   [0][0, &proc{}] += 21
#   'ok'
# }, '[ruby-core:30534]'

test_end
