=begin
describe "Group#notify" do
  it "works" do
    group = Dispatch::Group.new
    group.notify (Dispatch::Queue.main) { p 42 } 
  end
end
=end

class TestDispatchOnce
  def do_test1; Dispatch.once { @test1 ||= 0; @test1 += 1 }; end
  def get_test1; @test1; end
  def do_test2; Dispatch.once { @test2 ||= 0; @test2 += 1 }; end
  def get_test2; @test2; end
  def do_test3; Dispatch.once { @test3 ||= 0; @test3 += 1 }; end
  def get_test3; @test3; end
end

describe "Dispatch.once" do
  xit "yields a block just once" do
    obj = TestDispatchOnce.new
    threads = []
    8.times do
      threads << Thread.new do
autorelease_pool {
        10.times { obj.do_test1; sleep 0.01; obj.do_test2; sleep 0.01; obj.do_test3 }
}
      end
    end
    threads.each { |t| t.join }
    obj.get_test1.should == 1
    obj.get_test2.should == 1
    obj.get_test3.should == 1
  end

  # RM-628
  it "should work just once" do
    @sum = 0
    5.times do
      Dispatch.once {@sum += 2}
      Dispatch.once {@sum += 5}
    end
    @sum.should == 7  #=> Expected: 7

    @sum = 0
    threads = []
    5.times do
      threads << Thread.new do
        autorelease_pool {
          Dispatch.once {@sum += 2}
          Dispatch.once {@sum += 5}
        }
      end
    end
    threads.each { |t| t.join }
    @sum.should == 7  #=> Expected: 7
  end
end
