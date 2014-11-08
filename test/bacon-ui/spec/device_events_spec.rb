class DeviceSpecController < UIViewController
  def loadView
    frame = UIScreen.mainScreen.applicationFrame
    frame.origin = CGPointZero
    self.view = UIImageView.alloc.initWithFrame(frame)
    view.image = UIImage.imageNamed('We Need You.jpg')
  end

  def shouldAutorotateToInterfaceOrientation(orientation)
    true
  end

  def supportedInterfaceOrientations
    UIInterfaceOrientationMaskAll
  end

  def shouldAutorotate
    true
  end

  # This is all for `shake` support

  attr_accessor :shaked
  def shaked?
    @shaked
  end

  def viewWillAppear(animated)
    super
    becomeFirstResponder
  end

  def viewDidDisappear(animated)
    super
    resignFirstResponder
  end

  def canBecomeFirstResponder
    true
  end

  def motionEnded(motion, withEvent:event)
    @shaked = motion == UIEventSubtypeMotionShake
  end

  # Accelerometer support

  def enableAccelerometer=(flag)
    UIAccelerometer.sharedAccelerometer.delegate = (flag == true ? self : nil)
  end

  attr_reader :accelerationData
  def accelerometer(accelerometer, didAccelerate:acceleration)
    @accelerationData = acceleration
  end
end

describe "Bacon::Functional::API, concerning device events" do
  tests DeviceSpecController

  after do
    rotate_device :to => :portrait
  end

  it "changes device orientation" do
    rotate_device :to => :landscape, :button => :right
    controller.interfaceOrientation.should == UIInterfaceOrientationLandscapeRight

    rotate_device :to => :landscape, :button => :left
    controller.interfaceOrientation.should == UIInterfaceOrientationLandscapeLeft

    rotate_device :to => :portrait,  :button => :bottom
    controller.interfaceOrientation.should == UIInterfaceOrientationPortrait

    rotate_device :to => :portrait,  :button => :top
    controller.interfaceOrientation.should == UIInterfaceOrientationPortraitUpsideDown
  end

  it "has default orientations for portrait and landscape for when the :button option is omitted" do
    rotate_device :to => :landscape
    controller.interfaceOrientation.should == UIInterfaceOrientationLandscapeLeft

    rotate_device :to => :portrait
    controller.interfaceOrientation.should == UIInterfaceOrientationPortrait
  end

  it "creates a shake motion gesture (for undo support, for instance)" do
    shake
    controller.should.be.shaked
  end

  xit "sends accelerometer events" do
    with_accelerometer do
      accelerate :x => 0.5, :y => 0.5, :z => 0.5
    end
    controller.accelerationData.x.should == 0.5
    controller.accelerationData.y.should == 0.5
    controller.accelerationData.z.should == 0.5
  end

  def with_accelerometer
    controller.enableAccelerometer = true
    yield
  ensure
    controller.enableAccelerometer = false
  end
end
