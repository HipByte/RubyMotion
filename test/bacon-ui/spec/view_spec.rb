describe "Bacon::Functional::API, concerning location helpers" do
  extend Bacon::Functional::API

  def inset
    Bacon::Functional::API::LOCATION_TO_POINT_INSET
  end

  it "returns the points corresponding to the view" do
    view = UIView.alloc.initWithFrame(CGRectMake(100, 100, 100, 100))
    _location_to_point(view, :top_left).should     == CGPointMake(100+inset, 100+inset)
    _location_to_point(view, :top).should          == CGPointMake(150,       100+inset)
    _location_to_point(view, :top_right).should    == CGPointMake(200-inset, 100+inset)
    _location_to_point(view, :right).should        == CGPointMake(200-inset, 150)
    _location_to_point(view, :bottom_right).should == CGPointMake(200-inset, 200-inset)
    _location_to_point(view, :bottom).should       == CGPointMake(150,       200-inset)
    _location_to_point(view, :bottom_left).should  == CGPointMake(100+inset, 200-inset)
    _location_to_point(view, :left).should         == CGPointMake(100+inset, 150)
  end

  it "returns the opposite of a location" do
    _location_opposite(:top_left).should     == :bottom_right
    _location_opposite(:top).should          == :bottom
    _location_opposite(:top_right).should    == :bottom_left
    _location_opposite(:right).should        == :left
    _location_opposite(:bottom_right).should == :top_left
    _location_opposite(:bottom).should       == :top
    _location_opposite(:bottom_left).should  == :top_right
    _location_opposite(:left).should         == :right
  end
end

class ContainerView < UIView
end

class SimpleViewController < UIViewController
  attr_reader :purpleView, :blueView, :redView

  def loadView
    frame = UIScreen.mainScreen.applicationFrame
    frame.origin = CGPointZero
    self.view = ContainerView.alloc.initWithFrame(frame)
    view.accessibilityLabel = 'Container view'

    @purpleView = UIView.alloc.initWithFrame(CGRectMake(100, 100, 100, 100))
    @purpleView.backgroundColor = UIColor.purpleColor
    @purpleView.accessibilityLabel = 'Purple view'
    view.addSubview(@purpleView)

    @blueView = UIView.alloc.initWithFrame(CGRectMake(25, 25, 50, 50))
    @blueView.backgroundColor = UIColor.blueColor
    @blueView.accessibilityLabel = 'Blue view'
    @purpleView.performSelector('addSubview:', withObject:@blueView, afterDelay:0.5)

    @redView = UIView.alloc.initWithFrame(CGRectMake(110, 25, 75, 75))
    @redView.backgroundColor = UIColor.redColor
    @redView.accessibilityLabel = 'Red view'
    view.addSubview(@redView)
  end
end

describe "UIView extensions" do
  tests SimpleViewController

  it "returns the first subview with the specified accessibility label" do
    window.viewByName('Container view', 1).should == controller.view
    controller.view.viewByName('Purple view', 1).should == controller.purpleView
    controller.blueView.viewByName('Purple view', 1).should == nil
  end

  it "keeps trying to find a view by accessibility label during the timeout" do
    # This button shows up 0.5 second after the other views
    window.viewByName('Blue view', 0.1).should == nil
    window.viewByName('Blue view', 0.6).should == controller.blueView
  end

  it "looks through all superviews, until it finds a matching class" do
    controller.purpleView.up(UIButton, 0.1).should == nil
    controller.purpleView.up(ContainerView, 0.6).should == controller.view
  end

  it "keeps trying to look through all superviews, until it finds a matching class, during the timeout" do
    controller.blueView.up(ContainerView, 0.1).should == nil
    controller.blueView.up(ContainerView, 0.6).should == controller.view
  end

  it "returns all views of a specific class and sorts them top-left to bottom-right" do
    window.viewsByClass(UIButton, 0.1).should == []
    window.viewsByClass(ContainerView, 0.1).should == [controller.view]
    window.viewsByClass(UIView, 0.1).should == [
      controller.view,
      controller.redView,
      controller.purpleView
    ]
  end

  it "keeps trying to find a view by class during the timeout" do
    controller.purpleView.viewsByClass(UIView, 0.1).should == []
    controller.purpleView.viewsByClass(UIView, 0.6).should == [controller.blueView]
  end
end

describe "Bacon::Functional::API, concerning device events" do
  tests SimpleViewController

  it "finds a view by its accessibility label" do
    view('Purple view').should == controller.purpleView
    view('Blue view').should == controller.blueView
  end

  it "finds views by class" do
    views(ContainerView).should == [controller.view]
  end

  it "returns a view immediately if given instead of an accessibility label" do
    view = controller.purpleView
    # This will raise if the #view helper would not actually return the view immediately
    def window.viewByName(accessibilityLabel)
      raise 'Oh noes!'
    end
    view(view).should == view
  end

  it "raises if no view by label could be found after the `timeout` passes" do
    start = Time.now.to_i
    e = catch_bacon_error { view('Does not exist') }
    Time.now.to_i.should >= (start + 3)
    e.message.should == "Unable to find a view with label `Does not exist'"
  end

  it "raises if no views by class could be found after the `timeout` passes" do
    start = Time.now.to_i
    e = catch_bacon_error { views(UITableView) }
    Time.now.to_i.should >= (start + 3)
    e.message.should == "Unable to find any view of class `UITableView'"
  end

  def catch_bacon_error
    e = nil
    begin
      yield
    rescue Bacon::Error => e
    end
    e.should.not == nil
    e.count_as.should == :error
    e
  end
end
