class PaintView < UIView
  def initWithFrame(ect)
    if super
      path = NSBundle.mainBundle.pathForResource('erase', ofType:'caf')
      url = NSURL.fileURLWithPath(path)
      @eraseSound = AVAudioPlayer.alloc.initWithContentsOfURL(url,
        error:nil)
      @paths = []
    end
    self
  end

  def drawRect(rect)
    UIColor.blackColor.set
    UIBezierPath.bezierPathWithRect(rect).fill
    @paths.each do |path, color|
      color.set
      path.stroke
    end
  end

  def touchesBegan(touches, withEvent:event)
    bp = UIBezierPath.alloc.init#bezierPath
    bp.lineWidth = 3.0
    random_color = begin
      red, green, blue = rand(100), rand(100), rand(100)
      UIColor.alloc.initWithRed(red/100.0, green:green/100.0, blue:blue/100.0, alpha:1.0)
    end
    @paths << [bp, random_color]
  end

  def touchesMoved(touches, withEvent:event)
    touch = event.touchesForView(self).anyObject
    point = touch.locationInView(self)
    if @previousPoint and !@paths.empty?
      bp = @paths.last.first
      bp.moveToPoint(@previousPoint)
      bp.addLineToPoint(point)
    end
    @previousPoint = point
    setNeedsDisplay
  end

  def touchesEnded(touches, withEvent:event)
    @previousPoint = nil
  end

  def canBecomeFirstResponder
    true
  end

  def motionEnded(motion, withEvent:event)
    if motion == UIEventSubtypeMotionShake
      @paths.clear
      @eraseSound.play
      setNeedsDisplay
    end
  end
end

class AppDelegate
  def application(application, didFinishLaunchingWithOptions:launchOptions)
    window = UIWindow.alloc.initWithFrame(UIScreen.mainScreen.applicationFrame)

    pvrect = window.bounds
    pv = PaintView.alloc.initWithFrame(pvrect)
    pv.multipleTouchEnabled = true
    pv.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth
    window.addSubview(pv)
    pv.becomeFirstResponder

    window.makeKeyAndVisible
  end
end
