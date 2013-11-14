# TODO: Struct spec cause a crash

# describe "Struct" do
#   it "can be created with <100 fields" do
#     fields = (0...100).to_a.map { |n| "field#{n}".intern }
#     struct = Struct.new(*fields)
#     obj = struct.new
#     fields.each_with_index do |field, n|
#       obj.send(field).should == nil
#       obj.send(field.to_s + '=', n)
#     end
#     fields.each_with_index do |field, n|
#       obj.send(field).should == n
#     end
#   end

#   it "cannot be created with >100 fields" do
#     fields = (0...101).to_a.map { |n| "field#{n}".intern }
#     lambda { Struct.new(*fields) }.should.raise(ArgumentError)
#   end
# end

describe "Struct" do
  it "values are stored depending on the member type" do
    struct = MyStructTestConvert.new

    struct.m_long = 123
    struct.m_long.should == 123
    struct.m_long = 123.0
    struct.m_long.should == 123

    struct.m_ulong = 123
    struct.m_ulong.should == 123
    struct.m_ulong = 123.0
    struct.m_ulong.should == 123

    struct.m_longlong = 123
    struct.m_longlong.should == 123
    struct.m_longlong = 123.0
    struct.m_longlong.should == 123

    struct.m_ulonglong = 123
    struct.m_ulonglong.should == 123
    struct.m_ulonglong = 123.0
    struct.m_ulonglong.should == 123

    struct.m_double = 123
    struct.m_double.should == 123.0
    struct.m_double = 123.0
    struct.m_double.should == 123.0
  end
end