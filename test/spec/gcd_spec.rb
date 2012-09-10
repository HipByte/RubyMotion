=begin
describe "Group#notify" do
  it "works" do
    group = Dispatch::Group.new
    group.notify (Dispatch::Queue.main) { p 42 } 
  end
end
=end
