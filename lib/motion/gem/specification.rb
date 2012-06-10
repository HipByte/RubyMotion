
module Gem
  class Specification
    def motion
      spec = Motion::Gem::MotionSpec.new
      yield spec
      Motion::Gem::Manager.instance.specs[self.name] = spec
    end
  end
end
