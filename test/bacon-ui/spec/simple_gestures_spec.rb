class SmallControlsViewController < UIViewController
  attr_reader :tappableView, :switch, :lateKumbayaButton

  def loadView
    frame = UIScreen.mainScreen.applicationFrame
    frame.origin = CGPointZero
    self.view = UIView.alloc.initWithFrame(frame)
    #view.userInteractionEnabled = true
    view.accessibilityLabel = 'Container view'

    buttonMargin, buttonWidth, buttonHeight = 20, 150, 34
    buttonY = buttonMargin
    button = UIButton.buttonWithType(UIButtonTypeRoundedRect)
    button.setTitle("Kumbaya!", forState:UIControlStateNormal)
    button.frame = CGRectMake((frame.size.width - buttonWidth) / 2, buttonY, buttonWidth, buttonHeight)
    button.addTarget(self, action:'buttonTapped=:', forControlEvents:UIControlEventTouchUpInside)
    view.addSubview(button)

    buttonY += buttonHeight + buttonMargin
    @lateKumbayaButton = UIButton.buttonWithType(UIButtonTypeRoundedRect)
    @lateKumbayaButton.setTitle("Late Kumbaya!", forState:UIControlStateNormal)
    @lateKumbayaButton.frame = CGRectMake((frame.size.width - buttonWidth) / 2, buttonY, buttonWidth, buttonHeight)
    @lateKumbayaButton.addTarget(self, action:'buttonTapped=:', forControlEvents:UIControlEventTouchUpInside)
    # Delay adding the view so we can test that the `view` method retries until it's found
    view.performSelector('addSubview:', withObject:@lateKumbayaButton, afterDelay:1)

    switchY = buttonY + buttonHeight + buttonMargin
    @switch = UISwitch.alloc.initWithFrame(CGRectMake((frame.size.width - buttonWidth) / 2, switchY, buttonWidth, buttonHeight))
    @switch.accessibilityLabel = 'Switch control'
    @switch.on = false
    view.addSubview(@switch)

    # Nested tap gesture recognizers
    tappableViewContainerY = switchY + buttonHeight + buttonMargin
    container = UIView.alloc.initWithFrame(CGRectMake(10, tappableViewContainerY, buttonWidth + 50, buttonHeight + 50))
    container.backgroundColor = UIColor.greenColor
    view.addSubview(container)
    tappableViewY = buttonMargin
    @tappableView = UILabel.alloc.initWithFrame(CGRectMake(10, tappableViewY, buttonWidth, buttonHeight))
    @tappableView.userInteractionEnabled = true
    @tappableView.backgroundColor = UIColor.blueColor
    @tappableView.accessibilityLabel = 'Tappable view'
    @tappableView.textAlignment = UITextAlignmentCenter
    @tappableView.text = 'Taps: 0'
    container.addSubview(@tappableView)

    previous_recognizer = nil
    3.downto(1) do |taps|
      2.downto(1) do |touches|
        recognizer = UITapGestureRecognizer.alloc.initWithTarget(self, action:'handleTap:')
        recognizer.numberOfTapsRequired = taps
        recognizer.numberOfTouchesRequired = touches
        @tappableView.addGestureRecognizer(recognizer)

        recognizer.requireGestureRecognizerToFail(previous_recognizer) if previous_recognizer
        previous_recognizer = recognizer
      end
    end
  end

  #def viewWillAppear(animated)
    #super
    ##self.navigationItem.rightBarButtonItem = UIBarButtonItem.alloc.initWithBarButtonSystemItem(UIBarButtonSystemItemDone, target:self, action:'bla:')
  #end

  attr_accessor :buttonTapped
  # RM TODO: Assertion failed: (i != sel_to_attr.end()), function rb_attr_generic_getter, file vm.cpp, line 2753.
  #alias_method :buttonTapped?, :buttonTapped
  def buttonTapped?; @buttonTapped; end

  attr_reader :tapRecognizer
  attr_reader :tappedLocationInWindow
  attr_reader :tappedLocationInTappableView
  def handleTap(recognizer)
    @tappableView.text = "Taps: #{recognizer.numberOfTapsRequired}"
    @tapRecognizer = recognizer
    @tappedLocationInWindow = recognizer.locationInView(nil)
    @tappedLocationInTappableView = recognizer.locationInView(@tappableView)
  end
end

describe "Bacon::Functional::API, concerning one-shot gestures" do
  tests SmallControlsViewController

  it "flicks a switch" do
    flick "Switch control", :from => :left
    controller.switch.isOn.should == true
    flick "Switch control", :to   => :left
    controller.switch.isOn.should == false
  end

  # TODO the directions seem to be completely ignored.
  xit "uses the direction symbols to define the direction of the flick" do
    flick "Switch control", :to => :left
    controller.switch.isOn.should != true
  end

  it "taps a switch" do
    tap "Switch control", :at => :right
    controller.switch.isOn.should == true
    tap "Switch control", :at => :left
    controller.switch.isOn.should == false
  end

  it "by default taps at the center of a view" do
    highlight_touches!
    view = tap("Tappable view")
    controller.tappedLocationInWindow.should == view.superview.convertPoint(view.center, toView:nil)
  end

  it "taps at the :top_left of a view" do
    highlight_touches!
    view = tap("Tappable view", :at => :top_left)
    controller.tappedLocationInTappableView.x.should < view.frame.size.width / 2
    controller.tappedLocationInTappableView.y.should < view.frame.size.height / 2
  end

  it "taps at the :top of a view" do
    highlight_touches!
    view = tap("Tappable view", :at => :top)
    controller.tappedLocationInTappableView.y.should < view.frame.size.height / 2
  end

  it "taps at the :top_right of a view" do
    highlight_touches!
    view = tap("Tappable view", :at => :top_right)
    controller.tappedLocationInTappableView.x.should > view.frame.size.width / 2
    controller.tappedLocationInTappableView.y.should < view.frame.size.height / 2
  end

  it "taps at the :right of a view" do
    highlight_touches!
    view = tap("Tappable view", :at => :right)
    controller.tappedLocationInTappableView.x.should > view.frame.size.width / 2
  end

  it "taps at the :bottom_right of a view" do
    highlight_touches!
    view = tap("Tappable view", :at => :bottom_right)
    controller.tappedLocationInTappableView.x.should > view.frame.size.width / 2
    controller.tappedLocationInTappableView.y.should > view.frame.size.height / 2
  end

  it "taps at the :bottom of a view" do
    highlight_touches!
    view = tap("Tappable view", :at => :bottom)
    controller.tappedLocationInTappableView.y.should > view.frame.size.height / 2
  end

  it "taps at the :bottom_left of a view" do
    highlight_touches!
    view = tap("Tappable view", :at => :bottom_left)
    controller.tappedLocationInTappableView.x.should < view.frame.size.width / 2
    controller.tappedLocationInTappableView.y.should > view.frame.size.height / 2
  end

  it "taps at the :left of a view" do
    highlight_touches!
    view = tap("Tappable view", :at => :left)
    controller.tappedLocationInTappableView.x.should < view.frame.size.width / 2
  end

  #it "taps at a specific point in window coordinates" do
    #view  = controller.tappableView
    #point = CGPointMake(view.frame.origin.x + 10, view.frame.origin.y + 10)
    #point = view.superview.convertPoint(point, toView:nil)
    #tap "Tappable view", :at => point
    #controller.tappedLocationInWindow.should == point
  #end

  it "taps buttons" do
    tap "Kumbaya!"
    controller.buttonTapped.currentTitle.should == "Kumbaya!"
    # this one actually shows up a second later
    tap "Late Kumbaya!"
    controller.buttonTapped.currentTitle.should == "Late Kumbaya!"
  end

  it "recognizes a single tap" do
    tap "Tappable view"
    controller.tapRecognizer.numberOfTapsRequired.should == 1
    controller.tapRecognizer.numberOfTouchesRequired.should == 1

    tap "Tappable view", :touches => 2
    controller.tapRecognizer.numberOfTapsRequired.should == 1
    controller.tapRecognizer.numberOfTouchesRequired.should == 2
  end

  it "recognizes a double tap" do
    tap "Tappable view", :times => 2
    controller.tapRecognizer.numberOfTapsRequired.should == 2
    controller.tapRecognizer.numberOfTouchesRequired.should == 1

    tap "Tappable view", :times => 2, :touches => 2
    controller.tapRecognizer.numberOfTapsRequired.should == 2
    controller.tapRecognizer.numberOfTouchesRequired.should == 2
  end

  it "recognizes a triple tap" do
    tap "Tappable view", :times => 3
    controller.tapRecognizer.numberOfTapsRequired.should == 3
    controller.tapRecognizer.numberOfTouchesRequired.should == 1

    tap "Tappable view", :times => 3, :touches => 2
    controller.tapRecognizer.numberOfTapsRequired.should == 3
    controller.tapRecognizer.numberOfTouchesRequired.should == 2
  end
end
