describe "Procs" do
  it "are based on com.rubymotion.Proc" do
    obj = Proc.new {}
    obj.class.should == Proc
    obj.class.getName.should == 'com.rubymotion.Proc'
  end

  it "can be passed to Java methods expecting a java.lang.Runnable" do
    $proc_runnable_ok = false
    thr = Java::Lang::Thread.new -> { $proc_runnable_ok = true }
    thr.start
    thr.join
    $proc_runnable_ok.should be_true
  end
end
