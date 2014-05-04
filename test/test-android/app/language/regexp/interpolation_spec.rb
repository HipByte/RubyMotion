class Language_Regexp_Interpolation_Mock1 < Java::Lang::Object
  def to_s
    'class_with_to_s'
  end
end

describe "Regexps with interpolation" do

  it "allow interpolation of strings" do
    str = "foo|bar"
    /#{str}/.should == /foo|bar/
  end

  it "allows interpolation of literal regexps" do
    re = /foo|bar/
    #/#{re}/.should == /(?-mix:foo|bar)/
    /#{re}/.should == /(?m-ix:foo|bar)/
  end

  it "allows interpolation of any class that responds to to_s" do
    o = Language_Regexp_Interpolation_Mock1.new
    /#{o}/.should == /class_with_to_s/
  end

  it "allows interpolation which mixes modifiers" do
    re = /foo/i
    #/#{re} bar/m.should == /(?i-mx:foo) bar/m
    /#{re} bar/m.should == /(?mi-x:foo) bar/m
  end

  it "allows interpolation to interact with other Regexp constructs" do
    str = "foo)|(bar"
    /(#{str})/.should == /(foo)|(bar)/

    str = "a"
    /[#{str}-z]/.should == /[a-z]/
  end
  
  # MacRuby TODO: These fail to parse with `macruby`, but not with `miniruby`
  #
  # it "gives precedence to escape sequences over substitution" do
  #   str = "J"
  #   /\c#{str}/.to_s.should == '(?-mix:\c#' + '{str})'
  # end  

  it "throws RegexpError for malformed interpolation" do
    s = ""
    lambda { /(#{s}/ }.should raise_error(RegexpError)
    s = "("
    lambda { /#{s}/ }.should raise_error(RegexpError)
  end

  it "allows interpolation in extended mode" do
    var = "#comment\n  foo  #comment\n  |  bar"
    (/#{var}/x =~ "foo").should == (/foo|bar/ =~ "foo")
  end

  it "allows escape sequences in interpolated regexps" do
    escape_seq = %r{"\x80"}n
    #%r{#{escape_seq}}n.should == /(?-mix:"\x80")/n
    %r{#{escape_seq}}n.should == /(?m-ix:"\x80")/n
  end
end
