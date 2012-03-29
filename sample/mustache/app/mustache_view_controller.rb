class MustacheViewController < UIViewController
  def loadView
    self.view = UIImageView.alloc.init
    @debug_face = false # Set to true to debug face features.
  end

  def viewDidLoad
    view.image = UIImage.imageNamed('matz.jpg')
    view.contentMode = UIViewContentModeScaleAspectFit
  end

  def viewDidAppear(animated)
    # CoreImage used a coordinate system which is flipped on the Y axis
    # compared to UIKit. Also, a UIImageView can return an image larger than
    # itself. To properly translate points, we use an affine transform.
    transform = CGAffineTransformMakeScale(view.bounds.size.width / view.image.size.width, -1 * (view.bounds.size.height / view.image.size.height))
    transform = CGAffineTransformTranslate(transform, 0, -view.image.size.height)

    @detector ||= CIDetector.detectorOfType CIDetectorTypeFace, context:nil, options: { CIDetectorAccuracy: CIDetectorAccuracyHigh }
    image = CIImage.imageWithCGImage(view.image.CGImage)
    @detector.featuresInImage(image).each do |feature|
      next unless feature.hasMouthPosition and feature.hasLeftEyePosition and feature.hasRightEyePosition

      if @debug_face
        [feature.leftEyePosition,feature.rightEyePosition,feature.mouthPosition].each do |pt|
          v = UIView.alloc.initWithFrame CGRectMake(0, 0, 20, 20)
          v.backgroundColor = UIColor.greenColor.colorWithAlphaComponent(0.2)
          pt = CGPointApplyAffineTransform(pt, transform)
          v.center = pt
          view.addSubview(v)
        end
      end

      mustacheView = UIImageView.alloc.init
      mustacheView.image = UIImage.imageNamed('mustache')
      mustacheView.contentMode = UIViewContentModeScaleAspectFit

      w = feature.bounds.size.width
      h = feature.bounds.size.height / 5
      x = (feature.mouthPosition.x + (feature.leftEyePosition.x + feature.rightEyePosition.x) / 2) / 2 - w / 2
      y = feature.mouthPosition.y

      mustacheView.frame = CGRectApplyAffineTransform([[x, y], [w, h]], transform)

      mustacheAngle = Math.atan2(feature.leftEyePosition.x - feature.rightEyePosition.x, feature.leftEyePosition.y - feature.rightEyePosition.y) + Math::PI/2
      mustacheView.transform = CGAffineTransformMakeRotation(mustacheAngle) 
 
      view.addSubview(mustacheView)
    end
  end

  def shouldAutorotateToInterfaceOrientation(*)
    view.subviews.each { |v| v.removeFromSuperview }
    viewDidAppear(true)
    true
  end
end
