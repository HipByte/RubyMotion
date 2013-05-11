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
