class AppDelegate
  def application(application, didFinishLaunchingWithOptions:launchOptions)
    window = UIWindow.alloc.initWithFrame(UIScreen.mainScreen.bounds)
    tabbar = UITabBarController.alloc.init
    tabbar.viewControllers = [BeerMap.alloc.init, BeerList.alloc.init]
    tabbar.selectedIndex = 0
    @beer_details_controller = BeerDetailsController.alloc.init
    window.rootViewController = UINavigationController.alloc.initWithRootViewController(tabbar)
    window.rootViewController.wantsFullScreenLayout = true
    window.makeKeyAndVisible
    return true
  end

  attr_reader :beer_details_controller
end
