# macbacon-ui extensions.
#
# Copyright (C) 2012 Eloy Durán eloy.de.enige@gmail.com
#
# Bacon is freely distributable under the terms of an MIT-style license.
# See COPYING or http://www.opensource.org/licenses/mit-license.php.

# TODO make it pwetty
class TouchHighlightView < UIView
  DIAMETER = 7

  def self.forTouch(touch)
    touch.window.addSubview(alloc.initWithTouch(touch)) if touch.window
  end

  def self.updateLocationForTouch(touch)
    if highlight = highlightForTouch(touch)
      highlight.updateLocation
    end
  end

  def self.removeForTouch(touch)
    performSelector('reallyRemoveForTouch:', withObject:touch, afterDelay:0.1)
  end

  def self.reallyRemoveForTouch(touch)
    if highlight = highlightForTouch(touch)
      highlight.removeFromSuperview
    end
  end

  def self.highlightForTouch(touch)
    # If the touch has no window anymore, then the window has already been destroyed.
    touch.window.subviews.find { |v| v.is_a?(TouchHighlightView) && v.touch == touch } if touch.window
  end

  attr_reader :touch

  def initWithTouch(touch)
    @touch = touch
    if initWithFrame(highlightFrame)
      self.backgroundColor = UIColor.redColor
    end
    self
  end

  def highlightFrame
    point = @touch.locationInView(nil)
    offset = (DIAMETER-1)/2
    CGRectMake(point.x-offset, point.y-offset, DIAMETER, DIAMETER)
  end

  def updateLocation
    self.frame = highlightFrame
  end
end

module UIApplicationExt
  attr_accessor :logEvents
  attr_accessor :highlightTouches

  def sendEvent(event)
    if @logEvents
      NSLog(event.description)
    end

    # TODO this code breaks most gestures
    if @highlightTouches
      event.allTouches.each do |touch|
        case touch.phase
        when UITouchPhaseBegan
          TouchHighlightView.forTouch(touch)
        when UITouchPhaseMoved
          TouchHighlightView.updateLocationForTouch(touch)
        when UITouchPhaseStationary
          # nothing
        when UITouchPhaseEnded, UITouchPhaseCancelled
          TouchHighlightView.removeForTouch(touch)
        end
      end
    end

    super
  end
end

module RunLoopHelpers
  extend self

  MIN_INTERVAL = 0.01

  # This will halt the current call stack while still process runloop sources.
  #
  # The edge version of MacBacon uses this pattern for all the `wait` methods,
  # which is why this undocumented version is called `proper_wait`.
  #
  # You are free to use this, but be aware that it will be deprecated in the
  # future when a new version of MacBacon is released and merged into
  # RubyMotion.
  def proper_wait(sec)
    CFRunLoopRunInMode(KCFRunLoopDefaultMode, sec, false)
  end

  # Keeps trying the block until it returns a truthy value or the `timeout`
  # passes. The default `timeout` is 3 seconds.
  #
  # Returns the return value of the block.
  def wait_till(timeout = Bacon::Functional.default_timeout)
    result = nil
    interval = MIN_INTERVAL
    while interval < timeout
      # First sleep for a bit, otherwise it can happen that even if a view
      # (e.g. a button) is found, it won't properly respond to touches yet.
      proper_wait(interval)
      break if result = yield
      interval *= 2
    end
    result
  end
end

module UIViewExt
  def viewByName(accessibilityLabel, timeout = Bacon::Functional.default_timeout)
    RunLoopHelpers.wait_till(timeout) { _viewByName(accessibilityLabel) }
  end

  def viewsByClass(viewClass, timeout = Bacon::Functional.default_timeout)
    views = RunLoopHelpers.wait_till(timeout) { v = _viewsByClass(viewClass); v if !v.empty? } || []
    # sort by Y first, then X
    views.sort_by { |v| v.convertPoint(v.bounds.origin, toView:nil).to_a.reverse }
  end

  def up(viewClass, timeout = Bacon::Functional.default_timeout)
    RunLoopHelpers.wait_till(timeout) do
      view = self
      view = view.superview while view && !view.is_a?(viewClass)
      view
    end
  end

  private

  def _viewByName(accessibilityLabel)
    subviews.each do |subview|
      if subview.accessibilityLabel == accessibilityLabel
        return subview
      elsif found = subview.send(:_viewByName, accessibilityLabel)
        return found
      end
    end
    nil
  end

  def _viewsByClass(viewClass)
    result = []
    subviews.each do |view|
      result << view if view.is_a?(viewClass)
      result.concat(view.send(:_viewsByClass, viewClass))
    end
    result
  end
end
UIView.send(:include, UIViewExt)

module Bacon
  class Context
    # TODO
    # * :navigation => true
    # * :tab => true
    def tests(controller_class, options = {})
      @controller_class, @options = controller_class, options
      extend Bacon::Functional::API
      extend Bacon::Functional::ContextExt
    end
  end

  module Functional
    module ContextExt
      def self.extended(context)
        context.before do
          # Ensure a window exists and is on screen.
          window
        end

        context.after do
          # Disable logging events after each spec
          app = UIApplication.sharedApplication
          if app.respond_to?(:logEvents=)
            app.logEvents = app.highlightTouches = false
          end

          # Remove window and ensure a new one will be created on the next run.
          window.removeFromSuperview
          proper_wait(0.3) # give objects a chance to do their cleanup, otherwise sometimes a segfault will occur
          @window = nil
          @controller = nil
        end
      end

      def window
        unless @window
          @window = UIWindow.alloc.initWithFrame(UIScreen.mainScreen.bounds)
          # On some iOS/simulator versions the background isn't cleared before
          # a new window is shown. Make our windows black, just to make it a
          # bit prettier.
          @window.backgroundColor = UIColor.blackColor
          @window.rootViewController = controller
        end
        @window.makeKeyAndVisible
        @window
      end

      attr_accessor :controller

      def controller
        @controller ||= begin
          c = nil
          if @options[:id]
            c = storyboard.instantiateViewControllerWithIdentifier(@options[:id])
          else
            c = @controller_class.alloc.init
          end
          send(@options[:after_created], c) if @options[:after_created]
          c
        end
      end

      def storyboard
        @storyboard ||= UIStoryboard.storyboardWithName(@options[:storyboard] || 'MainStoryboard', bundle:nil)
      end
    end

    class << self
      # The default timeout value, for the view finder methods, in seconds.
      attr_accessor :default_timeout

      # The default duration, for gestures, in seconds.
      attr_accessor :default_duration
    end
    self.default_timeout = 3
    self.default_duration = 0.25

    module API
      include RunLoopHelpers

      attr_accessor :window

      # Gets overriden by ContextExt#window when the spec context is configured
      # to run against a specific controller.
      def window
        UIApplication.sharedApplication.keyWindow
      end

      def log_events!
        app = UIApplication.sharedApplication
        app.extend(UIApplicationExt) unless app.respond_to?(:logEvents)
        app.logEvents = true
      end

      # Calling this will draw a red dot at each location a touch occurs.
      #
      # Note, however, that at this moment this *will* break most gestures. If
      # you have a good idea of how to make this work then please file a ticket.
      def highlight_touches!
        app = UIApplication.sharedApplication
        app.extend(UIApplicationExt) unless app.respond_to?(:logEvents)
        app.highlightTouches = true
      end

      # Returns a list of points interpolated between `from` and `to`.
      #
      # The `from` and `to` points should be in window coordinates.
      def linear_interpolate(from, to, number_of_points = nil)
        number_of_points ||= 20
        interval = 1.0 / number_of_points
        points = Array.new(number_of_points-2) { |i| _linear_interpolate_point(from, to, (i+1)*interval) }
        points.unshift(from)
        points.push(to)
        points
      end

      def view(label)
        return label if label.is_a?(UIView)
        window.viewByName(label) ||
          raise(Bacon::Error.new(:error, "Unable to find a view with label `#{label}'"))
      end

      def views(view_class)
        views = window.viewsByClass(view_class)
        if views.empty?
          raise(Bacon::Error.new(:error, "Unable to find any view of class `#{view_class.name}'"))
        end
        views
      end

      def rotate_device(options)
        orientation = case options.values_at(:to, :button).compact
                      when [:portrait, :bottom], [:portrait]
                        UIInterfaceOrientationPortrait
                      when [:portrait, :top]
                        UIInterfaceOrientationPortraitUpsideDown
                      when [:landscape, :left], [:landscape]
                        UIInterfaceOrientationLandscapeLeft
                      when [:landscape, :right]
                        UIInterfaceOrientationLandscapeRight
                      end

        if UIDevice.currentDevice.orientation != orientation
          _event_generator.setOrientation(orientation)
          proper_wait(0.6)
        end
      end

      def accelerate(options)
        duration = options[:duration] || Functional.default_duration
        _event_generator.sendAccelerometerX(options[:x], Y:options[:y], Z:options[:z], duration:duration)
        proper_wait(duration)
      end

      def shake
        _event_generator.shake
        proper_wait(MIN_INTERVAL)
      end

      def tap(label_or_view, options = {})
        view     = view(label_or_view)
        taps     = options[:times]   || 1
        touches  = options[:touches] || 1
        location = _coerce_location_to_point(view, options[:at], false) || view.superview.convertPoint(view.center, toView:nil)

        _event_generator.sendTaps(taps,
                         location:location,
              withNumberOfTouches:touches,
                           inRect:window.frame)
        proper_wait(taps * 0.4)

        view
      end

      def flick(label_or_view, options)
        view     = view(label_or_view)
        from, to = _extract_start_and_end_points(view, options)
        duration = options[:duration] || Functional.default_duration

        _event_generator.sendFlickWithStartPoint(from, endPoint:to, duration:duration)
        proper_wait(duration)

        view
      end

      def pinch_open(label_or_view, options = {})
        view     = view(label_or_view)
        duration = options[:duration] || Functional.default_duration

        options[:from] ||= :left unless options[:to]
        from, to = _extract_start_and_end_points(view, options)

        EventDispatcher.dispatch(duration) do
          _event_generator.sendPinchOpenWithStartPoint(from, endPoint:to, duration:duration)
        end

        view
      end

      def pinch_close(label_or_view, options = {})
        view     = view(label_or_view)
        duration = options[:duration] || Functional.default_duration

        options[:from] ||= :right unless options[:to]
        from, to = _extract_start_and_end_points(view, options)

        EventDispatcher.dispatch(duration) do
          _event_generator.sendPinchCloseWithStartPoint(from, endPoint:to, duration:duration)
        end

        view
      end

      # TODO add scroll helper? E.g. `scroll_down 'Scroll view'` would do `drag 'Scroll view', :from => :bottom`?
      def drag(label_or_view, options)
        view     = view(label_or_view)
        duration = options[:duration] || Functional.default_duration
        touches  = options[:touches]  || 1

        unless points = options[:points]
          from, to = _extract_start_and_end_points(view, options)
          points   = linear_interpolate(from, to, options[:number_of_points])
        end

        pointer  = Pointer.new(CGPoint.type, points.size)
        points.each.with_index do |point, i|
          pointer[i] = point
        end

        EventDispatcher.dispatch(duration) do
          _event_generator.sendMultifingerDragWithPointArray(pointer, numPoints:points.size, duration:duration, numFingers:touches)
        end

        view
      end

      # TODO offset from the center in the same way that UIAutomation does (values between 0 and 1)
      def rotate(label_or_view, options)
        view     = view(label_or_view)
        center   = view.superview.convertPoint(view.center, toView:nil)
        angle    = options[:radians] || (options[:degrees] && options[:degrees] * (Math::PI/180)) || Math::PI
        touches  = options[:touches] || 2
        radius   = (view.frame.size.width / 2.0)
        duration = options[:duration] || Functional.default_duration

        EventDispatcher.dispatch(duration) do
          _event_generator.sendRotate(center, withRadius:radius, rotation:angle, duration:duration, touchCount:touches)
        end

        view
      end

      private

      def _event_generator
        UIASyntheticEvents.sharedEventGenerator
      end

      def _location_opposite(location)
        case location
        when :top_left
          :bottom_right
        when :top
          :bottom
        when :top_right
          :bottom_left
        when :right
          :left
        when :bottom_right
          :top_left
        when :bottom
          :top
        when :bottom_left
          :top_right
        when :left
          :right
        else
          raise ArgumentError, "Invalid location value `#{location}'."
        end
      end

      LOCATION_TO_POINT_INSET = 5

      def _location_to_point(view, location, raise_if_invalid = true)
        frame = view.frame
        case location
        when :top_left
          CGPointMake(CGRectGetMinX(frame) + LOCATION_TO_POINT_INSET, CGRectGetMinY(frame) + LOCATION_TO_POINT_INSET)
        when :top
          CGPointMake(CGRectGetMidX(frame),                           CGRectGetMinY(frame) + LOCATION_TO_POINT_INSET)
        when :top_right
          CGPointMake(CGRectGetMaxX(frame) - LOCATION_TO_POINT_INSET, CGRectGetMinY(frame) + LOCATION_TO_POINT_INSET)
        when :right
          CGPointMake(CGRectGetMaxX(frame) - LOCATION_TO_POINT_INSET, CGRectGetMidY(frame))
        when :bottom_right
          CGPointMake(CGRectGetMaxX(frame) - LOCATION_TO_POINT_INSET, CGRectGetMaxY(frame) - LOCATION_TO_POINT_INSET)
        when :bottom
          CGPointMake(CGRectGetMidX(frame),                           CGRectGetMaxY(frame) - LOCATION_TO_POINT_INSET)
        when :bottom_left
          CGPointMake(CGRectGetMinX(frame) + LOCATION_TO_POINT_INSET, CGRectGetMaxY(frame) - LOCATION_TO_POINT_INSET)
        when :left
          CGPointMake(CGRectGetMinX(frame) + LOCATION_TO_POINT_INSET, CGRectGetMidY(frame))
        else
          raise ArgumentError, "Invalid location value `#{location}'." if raise_if_invalid
        end
      end

      def _location_to_converted_point(view, location, raise_if_invalid = true)
        if sv = view.superview
          sv.convertPoint(_location_to_point(view, location, raise_if_invalid), toView:nil)
        else
          raise ArgumentError, "It is not possible to use the location constants on a view that has no superview."
        end
      end

      def _linear_interpolate_point(a, b, alpha)
        x = a.x + ((b.x-a.x) * alpha)
        y = a.y + ((b.y-a.y) * alpha)
        CGPointMake(x.round, y.round)
      end

      def _coerce_location_to_point(view, value, raise_if_invalid = true)
        case value
        when CGPoint then value
        when Symbol  then _location_to_converted_point(view, value, raise_if_invalid)
        end
      end

      def _extract_point(view, options, from_or_to)
        unless point = _coerce_location_to_point(view, options[from_or_to])
          other = from_or_to == :from ? :to : :from
          if options[other] && options[other].is_a?(Symbol)
            point = _location_to_converted_point(view, _location_opposite(options[other]))
          else
            raise ArgumentError, "No :#{from_or_to} location given and unable to inflect from :#{other} location `#{options[opposite].inspect}'."
          end
        end
        point
      end

      def _extract_start_and_end_points(view, options)
        from = _extract_point(view, options, :from)
        to   = _extract_point(view, options, :to)
        [from, to]
      end

      def _view(accessibilityLabel, error_message = nil)
        return accessibilityLabel if accessibilityLabel.is_a?(UIView)
        window.viewByName(accessibilityLabel) ||
          raise(Bacon::Error.new(:error, error_message || "Unable to find a view with label `#{accessibilityLabel}'"))
      end

      # This class wraps a block that will be executed on a GCD queue, but will
      # halt the main thread's call stack (while still handling the main thread's
      # runloop) until the block has completely finished its work.
      #
      # This is only meant for those events that are continuous and need more
      # time to be generated. E.g. a pinch gesture.
      class EventDispatcher
        include RunLoopHelpers

        def self.dispatch(duration, &block)
          new(duration, &block).call
        end

        attr_reader :done, :duration

        def initialize(duration, &block)
          @duration = duration
          @done     = false
          @block    = block
        end

        def call
          group = Dispatch::Group.new
          queue = Dispatch::Queue.concurrent
          queue.async(group, &@block)
          group.notify(queue) { @done = true }
          # First wait the standard duration, then block additionally until the
          # job has been actually finished.
          #
          # TODO have one mixin with wait helpers?
          proper_wait(@duration)
          proper_wait(MIN_INTERVAL) while !@done
        end
      end
    end

  end
end
