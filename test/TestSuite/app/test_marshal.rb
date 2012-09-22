test_begin "test_marshal"

assert_equal %q{{"k"=>"v"}}, proc{
  Marshal.load(Marshal.dump({"k"=>"v"}), lambda {|v| v})
}

test_end