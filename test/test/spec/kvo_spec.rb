class Observed1
  attr_accessor :name

  def self.automaticallyNotifiesObserversForKey(theKey)
    automatic = false
    if (theKey == "name")
        automatic = false
    else
        automatic = super
    end
    automatic
  end

  def name=(name)
    self.willChangeValueForKey("name")
    @name = name
    self.didChangeValueForKey("name")
  end
end

class Observed2
  attr_accessor :name
end

class Observer
  attr_reader :did_observe

  def observe(observed)
    observed.addObserver(self, forKeyPath: "name", options: 0, context: nil)
  end

  def unobserve(observed)
    observed.removeObserver(self, forKeyPath: "name") 
  end

  def observeValueForKeyPath(key_path, ofObject:object, change:change, context:context)
    @did_observe = true
  end
end

describe "KVO" do
  it "works for objects that implement the KVO interface manually" do
    observed = Observed1.new
    observed.name = "first"

    observer = Observer.new
    observer.observe(observed)

    observed.name = "second"
    observer.did_observe.should == true
    observer.unobserve(observed)
  end

  it "works for objects that use attr_accessor" do
    observed = Observed2.new
    observed.name = "first"

    observer = Observer.new
    observer.observe(observed)

    observed.name = "second"
    observer.did_observe.should == true
    observer.unobserve(observed)
  end
end

describe "KVC" do
  it "works for objects that use attr_accessor" do
    x = Observed2.new
    x.name = 'foo'
    x.valueForKey('name').should == 'foo'
    x.setValue('bar', forKey:'name')
    x.name == 'bar'
  end
end
