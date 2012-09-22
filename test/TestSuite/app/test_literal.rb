test_begin "test_literal"

# empty program
assert_equal '',                proc{ '' }
# assert_equal '',                proc{ ' ' }
# assert_equal '',                proc{ "\n" }

# special const
assert_equal 'true',            proc{ true }
assert_equal 'TrueClass',       proc{ true.class }
assert_equal 'false',           proc{ false }
assert_equal 'FalseClass',      proc{ false.class }
assert_equal '',                proc{ nil }
assert_equal 'nil',             proc{ nil.inspect }
assert_equal 'NilClass',        proc{ nil.class }
assert_equal 'sym',             proc{ :sym }
assert_equal ':sym',            proc{ :sym.inspect }
assert_equal 'Symbol',          proc{ :sym.class }
assert_equal '1234',            proc{ 1234 }
assert_equal 'Fixnum',          proc{ 1234.class }
assert_equal '1234',            proc{ 1_2_3_4 }
assert_equal 'Fixnum',          proc{ 1_2_3_4.class }
assert_equal '18',              proc{ 0x12 }
assert_equal 'Fixnum',          proc{ 0x12.class }
assert_equal '15',              proc{ 0o17 }
assert_equal 'Fixnum',          proc{ 0o17.class }
assert_equal '5',               proc{ 0b101 }
assert_equal 'Fixnum',          proc{ 0b101.class }
assert_equal '123456789012345678901234567890', proc{ 123456789012345678901234567890 }
assert_equal 'Bignum',          proc{ 123456789012345678901234567890.class }
assert_equal '2.0',             proc{ 2.0 }
assert_equal 'Float',           proc{ 1.3.class }

# self
assert_equal 'main',            proc{ self }
# assert_equal 'Object',          proc{ self.class }

# string literal
assert_equal 'a',               proc{ ?a }
assert_equal 'String',          proc{ ?a.class }
assert_equal 'A',               proc{ ?A }
assert_equal 'String',          proc{ ?A.class }
assert_equal "\n",              proc{ ?\n }
assert_equal 'String',          proc{ ?\n.class }
assert_equal ' ',               proc{ ?\  }
assert_equal 'String',          proc{ ?\ .class }
# assert_equal 'string',          proc{ "'string'" }
assert_equal 'string',          proc{ "string" }
assert_equal 'string',          proc{ %(string) }
assert_equal 'string',          proc{ %q(string) }
assert_equal 'string',          proc{ %Q(string) }
assert_equal 'string string',   proc{ "string string" }
assert_equal ' ',               proc{ " " }
assert_equal "\0",              proc{ "\0" }
assert_equal "\1",              proc{ "\1" }
assert_equal "3",               proc{ "\x33" }
assert_equal "\n",              proc{ "\n" }

# dynamic string literal
assert_equal '2',               proc{ "#{1 + 1}" }
assert_equal '16',              proc{ "#{2 ** 4}" }
assert_equal 'string',          proc{ s = "string"; "#{s}" }

# dynamic symbol literal
assert_equal 'a3c',             proc{ :"a#{1+2}c" }
assert_equal ':a3c',            proc{ :"a#{1+2}c".inspect }
assert_equal 'Symbol',          proc{ :"a#{1+2}c".class }

# xstring
# assert_equal "foo\n",           proc{ `echo foo` }
# assert_equal "foo\n",           proc{ s = "foo"; `echo #{s}` }

# regexp
assert_equal '',                proc{ //.source }
assert_equal 'Regexp',          proc{ //.class }
assert_equal '0',               proc{ // =~ "a" }
assert_equal '0',               proc{ // =~ "" }
assert_equal 'a',               proc{ /a/.source }
assert_equal 'Regexp',          proc{ /a/.class }
assert_equal '0',               proc{ /a/ =~ "a" }
assert_equal '0',               proc{ /test/ =~ "test" }
assert_equal '',                proc{ /test/ =~ "tes" }
assert_equal '0',               proc{ re = /test/; re =~ "test" }
assert_equal '0',               proc{ str = "test"; /test/ =~ str }
assert_equal '0',               proc{ re = /test/; str = "test"; re =~ str }

# dynacmi regexp
assert_equal 'regexp',          proc{ /re#{'ge'}xp/.source }
assert_equal 'Regexp',          proc{ /re#{'ge'}xp/.class }

# array
assert_equal 'Array',           proc{ [].class }
assert_equal '0',               proc{ [].size }
assert_equal '0',               proc{ [].length }
assert_equal '[]',              proc{ [].inspect }
assert_equal 'Array',           proc{ [0].class }
assert_equal '1',               proc{ [3].size }
assert_equal '[3]',             proc{ [3].inspect }
assert_equal '3',               proc{ a = [3]; a[0] }
assert_equal 'Array',           proc{ [1,2].class }
assert_equal '2',               proc{ [1,2].size }
assert_equal '[1, 2]',          proc{ [1,2].inspect }
assert_equal 'Array',           proc{ [1,2,3,4,5].class }
assert_equal '5',               proc{ [1,2,3,4,5].size }
assert_equal '[1, 2, 3, 4, 5]', proc{ [1,2,3,4,5].inspect }
assert_equal '1',               proc{ a = [1,2]; a[0] }
assert_equal '2',               proc{ a = [1,2]; a[1] }
assert_equal 'Array',           proc{ a = [1 + 2, 3 + 4, 5 + 6]; a.class }
assert_equal '[3, 7, 11]',      proc{ a = [1 + 2, 3 + 4, 5 + 6]; a.inspect }
assert_equal '7',               proc{ a = [1 + 2, 3 + 4, 5 + 6]; a[1] }
assert_equal '1',               proc{ ([0][0] += 1) }
assert_equal '1',               proc{ ([2][0] -= 1) }
assert_equal 'Array',           proc{ a = [obj = Object.new]; a.class }
assert_equal '1',               proc{ a = [obj = Object.new]; a.size }
assert_equal 'true',            proc{ a = [obj = Object.new]; a[0] == obj }
assert_equal '5',               proc{ a = [1,2,3]; a[1] = 5; a[1] }
assert_equal 'bar',             proc{ [*:foo];:bar }
assert_equal '[1, 2]',          proc{ def nil.to_a; [2]; end; [1, *nil] }
assert_equal '[1, 2]',          proc{ def nil.to_a; [1, 2]; end; [*nil] }
assert_equal '[0, 1, {2=>3}]',  proc{ [0, *[1], 2=>3] }, "[ruby-dev:31592]"


# hash
assert_equal 'Hash',            proc{ {}.class }
assert_equal '{}',              proc{ {}.inspect }
assert_equal 'Hash',            proc{ {1=>2}.class }
assert_equal '{1=>2}',          proc{ {1=>2}.inspect }
assert_equal '2',               proc{ h = {1 => 2}; h[1] }
assert_equal '0',               proc{ h = {1 => 2}; h.delete(1); h.size }
assert_equal '',                proc{ h = {1 => 2}; h.delete(1); h[1] }
assert_equal '2',               proc{ h = {"string" => "literal", "goto" => "hell"}; h.size }
assert_equal 'literal',         proc{ h = {"string"=>"literal", "goto"=>"hell"}; h["string"] }
assert_equal 'hell',            proc{ h = {"string"=>"literal", "goto"=>"hell"}; h["goto"] }

# range
assert_equal 'Range',           proc{ (1..2).class }
assert_equal '1..2',            proc{ (1..2).inspect }
assert_equal '1',               proc{ (1..2).begin }
assert_equal '2',               proc{ (1..2).end }
assert_equal 'false',           proc{ (1..2).exclude_end? }
assert_equal 'Range',           proc{ r = 1..2; r.class }
assert_equal '1..2',            proc{ r = 1..2; r.inspect }
assert_equal '1',               proc{ r = 1..2; r.begin }
assert_equal '2',               proc{ r = 1..2; r.end }
assert_equal 'false',           proc{ r = 1..2; r.exclude_end? }
assert_equal 'Range',           proc{ (1...3).class }
assert_equal '1...3',           proc{ (1...3).inspect }
assert_equal '1',               proc{ (1...3).begin }
assert_equal '3',               proc{ (1...3).end }
assert_equal 'true',            proc{ (1...3).exclude_end? }
assert_equal 'Range',           proc{ r = (1...3); r.class }
assert_equal '1...3',           proc{ r = (1...3); r.inspect }
assert_equal '1',               proc{ r = (1...3); r.begin }
assert_equal '3',               proc{ r = (1...3); r.end }
assert_equal 'true',            proc{ r = (1...3); r.exclude_end? }
assert_equal 'Range',           proc{ r = (1+2 .. 3+4); r.class }
assert_equal '3..7',            proc{ r = (1+2 .. 3+4); r.inspect }
assert_equal '3',               proc{ r = (1+2 .. 3+4); r.begin }
assert_equal '7',               proc{ r = (1+2 .. 3+4); r.end }
assert_equal 'false',           proc{ r = (1+2 .. 3+4); r.exclude_end? }
assert_equal 'Range',           proc{ r = (1+2 ... 3+4); r.class }
assert_equal '3...7',           proc{ r = (1+2 ... 3+4); r.inspect }
assert_equal '3',               proc{ r = (1+2 ... 3+4); r.begin }
assert_equal '7',               proc{ r = (1+2 ... 3+4); r.end }
assert_equal 'true',            proc{ r = (1+2 ... 3+4); r.exclude_end? }
assert_equal 'Range',           proc{ r = ("a".."c"); r.class }
assert_equal '"a".."c"',        proc{ r = ("a".."c"); r.inspect }
assert_equal 'a',               proc{ r = ("a".."c"); r.begin }
assert_equal 'c',               proc{ r = ("a".."c"); r.end }

assert_equal 'String',          proc{ __FILE__.class }
assert_equal 'Fixnum',          proc{ __LINE__.class }

###

# assert_equal 'ok', proc{
#   # this cause "called on terminated object".
#   ObjectSpace.each_object(Module) {|m| m.name.inspect }
#   :ok
# }

# assert_normal_exit proc{
#   begin
#     r = 0**-1
#     r + r
#   rescue
#   end
# }, '[ruby-dev:34524]'

# assert_normal_exit proc{
#   begin
#     r = Marshal.load("\x04\bU:\rRational[\ai\x06i\x05")
#     r + r
#   rescue
#   end
# }, '[ruby-dev:34536]'

assert_equal 'ok', proc{
  "#{}""#{}ok"
}, '[ruby-dev:38968]'

assert_equal 'ok', proc{
  "#{}o""#{}k""#{}"
}, '[ruby-core:25284]'

test_end