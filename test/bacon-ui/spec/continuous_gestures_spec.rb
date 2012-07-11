class ScrollViewController < UIViewController
  attr_reader :scrollView, :scrollViewRotation, :imageView

  def loadView
    @scrollViewRotation = 0

    frame = UIScreen.mainScreen.applicationFrame
    frame.origin = CGPointZero
    self.view = UIView.alloc.initWithFrame(frame)

    @scrollView = UIScrollView.alloc.initWithFrame(view.bounds)
    @scrollView.backgroundColor = UIColor.redColor
    @scrollView.delegate = self
    @scrollView.maximumZoomScale = 3
    view.addSubview(@scrollView)

    @imageView = UIImageView.alloc.initWithImage(UIImage.imageNamed('We Need You.jpg'))
    @imageView.frame = [[0, 0], @imageView.image.size]
    @scrollView.accessibilityLabel = 'Scroll view'

    @scrollView.contentSize = @imageView.image.size
    @scrollView.addSubview(@imageView)

    recognizer = UIRotationGestureRecognizer.alloc.initWithTarget(self, action:'handleRotation:')
    @scrollView.addGestureRecognizer(recognizer)
  end

  def viewForZoomingInScrollView(sv)
    @imageView
  end

  def handleRotation(recognizer)
    @scrollViewRotation = recognizer.rotation
    @scrollView.transform = CGAffineTransformMakeRotation(recognizer.rotation)
  end
end

describe "Bacon::Functional::API, concerning continuous gestures" do
  tests ScrollViewController

  it "creates 'pinch open' and 'pinch close' gesture events" do
    before = controller.scrollView.zoomScale
    pinch_open 'Scroll view'
    controller.scrollView.zoomScale.should > before

    before = controller.scrollView.zoomScale
    pinch_close 'Scroll view'
    controller.scrollView.zoomScale.should < before
  end

  # TODO currently it doesn't rotate exactly 90 degreese. I think this has to
  # do with the center point being off and the radius not being a perfect half
  # of the total diameter.
  it "creates rotate gesture events" do
    before = controller.scrollViewRotation
    rotate 'Scroll view', :degrees => 90
    controller.scrollViewRotation.should > before

    #before = controller.scrollView.transform
    #rotate 'Scroll view', :degrees => 90, :duration => 5
    #after = controller.scrollView.transform
    #expected = CGAffineTransformRotate(before, Math::PI/2)
    #CGAffineTransformEqualToTransform(after, expected).should == true
  end

  before do
    pinch_open 'Scroll view'
  end

  it "drags from point A to point B" do
    before = controller.scrollView.contentOffset
    drag 'Scroll view', :from => CGPointMake(310, 100), :to => CGPointMake(5, 150)
    controller.scrollView.contentOffset.x.should > before.x
    controller.scrollView.contentOffset.y.should < before.y
  end

  it "drags along the specified list of points" do
    view = controller.scrollView
    before = view.contentOffset
    drag 'Scroll view', :points => linear_interpolate(_location_to_point(view, :bottom_right), _location_to_point(view, :left))
    view.contentOffset.x.should > before.x
    view.contentOffset.y.should > before.y
  end

  it "drags with multiple fingers" do
    controller.scrollView.panGestureRecognizer.minimumNumberOfTouches = 3
    controller.scrollView.panGestureRecognizer.maximumNumberOfTouches = 3
    before = controller.scrollView.contentOffset
    drag 'Scroll view', :from => :right, :touches => 3
    controller.scrollView.contentOffset.x.should >  before.x
    controller.scrollView.contentOffset.y.should == before.y
  end
end
