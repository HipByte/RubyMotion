class StoryboardViewController < UIViewController

  # The view associated with this controller in the storyboard has a single
  # UILabel with an accessibility label of 'Storyboard' and a text value of
  # 'Hello, Rubymotion'

  def viewDidLoad
    label = UILabel.alloc.init
    label.text = 'Code'
    view.addSubview(label)
  end

end

describe "Storyboard support when not used" do
  tests StoryboardViewController

  it "does not load from storyboard without an id" do
    labels = views(UILabel)
    labels.count.should == 1
    labels.first.text.should == 'Code'
  end
end

shared "a controller from a storyboard" do
  it "has the label defined in the storyboard" do
    labels = views(UILabel)
    labels.count.should == 2
    view('Storyboard').text.should == 'Hello, RubyMotion'
  end
end

describe "Storyboard support defaults" do
  tests StoryboardViewController, :id => 'main'

  it "uses MainStoryboard if no name is provided" do
    @options[:storyboard_name].should == 'MainStoryboard'
  end

  behaves_like "a controller from a storyboard"
end

describe "Storyboard support with named storyboard" do
  tests StoryboardViewController, :storyboard_name => 'AlternateStoryboard', :id => 'alternate'

  behaves_like "a controller from a storyboard"
end
