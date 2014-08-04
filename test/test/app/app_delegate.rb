class ApplicationSubclass < (defined?(UIApplication) ? UIApplication : NSApplication)
end

class AppDelegate
  def application(application, didFinishLaunchingWithOptions:launchOptions)
    true
  end
end
