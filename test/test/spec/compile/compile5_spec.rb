# motion-support/motion/callbacks.rb
module MotionSupport
  module Callbacks
    class Callback #:nodoc:#
      def initialize(chain, filter, kind, options, klass)
      end
    end

    module ClassMethods
      def __update_callbacks(name, filters = [])
        yield :a, :b, [:c, :d]
      end

      def set_callback(name, *filter_list)
        mapped = nil

        __update_callbacks(name, filter_list, block) do |target, chain, type, filters, options|
          mapped ||= filters.map do |filter|
            Callback.new(chain, filter, type, options.dup, self)
          end

          options[:prepend] ? chain.prepend(*mapped) : chain.append(*mapped)

        end
      end

    end
  end
end

describe "compile5_spec" do
  it "should work" do
    1.should == 1
  end
end