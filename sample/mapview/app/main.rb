class Beer
  def initialize(lat, long, name)
    @name = name
    @coordinate = CLLocationCoordinate2D.new
    @coordinate.latitude = lat
    @coordinate.longitude = long
  end

  def title; @name; end
  def coordinate; @coordinate; end
end

class AppDelegate
  def application(application, didFinishLaunchingWithOptions:launchOptions)
    window = UIWindow.alloc.initWithFrame(UIScreen.mainScreen.applicationFrame)

    mvrect = window.bounds
    mv = MKMapView.alloc.initWithFrame(mvrect)
    mv.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth
 
    # Center on Brussels.
    region = MKCoordinateRegionMake(CLLocationCoordinate2D.new(50.85, 4.35), MKCoordinateSpanMake(3.1, 3.1))
    mv.setRegion(region)

    beers = [
      Beer.new(50.016667, 4.316667, 'Chimay'),
      Beer.new(49.639722, 5.348889, 'Orval'),
      Beer.new(50.178162, 5.219879, 'Rochefort'),
      Beer.new(51.284720, 4.656670, 'Westmalle'),
      Beer.new(50.895942, 2.721262, 'Westvleteren'),
      Beer.new(51.298800, 5.488570, 'Achel')
    ]
    beers.each { |beer| mv.addAnnotation(beer) }

    window.addSubview(mv)
    window.makeKeyAndVisible
  end
end
