BITS = RUBY_ARCH.include?('64') ? 64 : 32

if defined?(UIView)
  IOS_VERSION = Motion::Util::Version.new(ENV['deployment_target'])
  OSX_VERSION = nil
elsif defined?(NSView)
  IOS_VERSION = nil
  OSX_VERSION = Motion::Util::Version.new(ENV['deployment_target'])
end
unless IOS_VERSION || OSX_VERSION
  NSLog("ERROR: Unable to determin iOS and OS X deployment target version!")
  exit(1)
end

# Adapted from https://github.com/irrationalfab/PrettyBacon
module PrettyBacon
  def self.color(color, string)
    case color
    when :red
      "\e[31m#{string}\e[0m"
    when :green
      "\e[32m#{string}\e[0m"
    when :yellow
      "\e[33m#{string}\e[0m"
    when :none
      string
    else
      "\e[0m#{string}\e[0m"
    end
  end
end

module Bacon
  class Context
    # Add support for disabled specs
    #
    def xit(description, &block)
      if ENV['run-disabled']
        it(description, &block)
      else
        Counter[:disabled] += 1
        #Bacon.handle_requirement_begin(description, true)
        #Bacon.handle_requirement_end(nil)
        it(description) { Bacon.running_disabled_spec = true; true.should == true }
      end
    end

    alias_method :__it_before_conditionally, :it

    def it(*args, &block)
      if args.last.is_a?(Hash)
        options = args.pop
        if options.has_key?(:if) && !options[:if]
          return xit(*args, &block)
        elsif options.has_key?(:unless) && options[:unless]
          return xit(*args, &block)
        end
      end
      __it_before_conditionally(*args, &block)
    end

    def bits
      BITS
    end

    def sdk_version
      IOS_VERSION || OSX_VERSION
    end

    def ios?
      !IOS_VERSION.nil?
    end

    def osx?
      !OSX_VERSION.nil?
    end

    def osx_32bit?
      osx? && bits == 32
    end

    def capture_warning
      $last_rb_warn = nil
      ENV['RM_CAPTURE_WARNINGS'] = '1'
      yield
      $last_rb_warn
    ensure
      ENV.delete('RM_CAPTURE_WARNINGS')
    end
  end

  # Overrides the SpecDoxzRtput to provide colored output by default
  #
  # Based on https://github.com/zen-cms/Zen-Core and subsequently modified
  # which is available under the MIT License. Thanks YorickPeterse!
  #
  module PrettySpecDoxOutput

    def handle_specification_begin(name)
      if @needs_first_put
        @needs_first_put = false
        puts
      end
      @specs_depth = @specs_depth || 0
      puts spaces + name
      @specs_depth += 1
    end

    def handle_specification_end
      @specs_depth -= 1
      puts if @specs_depth.zero?
    end

    attr_accessor :running_disabled_spec

    #def handle_requirement_begin(description, disabled = false)
    def handle_requirement_begin(description)
      self.running_disabled_spec = false
      @start_time = Time.now.to_f
      @description = description
    end

    def handle_requirement_end(error)
      elapsed_time = ((Time.now.to_f - @start_time) * 1000).round

      if !error.empty?
        puts PrettyBacon.color(:red, "#{spaces}- #{@description} [FAILED]")
      #elsif @disabled
      elsif Bacon.running_disabled_spec
        puts PrettyBacon.color(:yellow, "#{spaces}- #{@description} [DISABLED]")
      else
        time_color = case elapsed_time
          when 0..200
            :none
          when 200..500
            :yellow
          else
            :red
          end

        if elapsed_time <= 1
          elapsed_time_string = ''
        elsif elapsed_time >= 1000
          elapsed_time_string = "(#{'%.1f' % (elapsed_time/1000.0)} s)"
        else
          elapsed_time_string = "(#{elapsed_time} ms)"
        end

        elapsed_time_string = PrettyBacon.color(time_color, " #{elapsed_time_string}") unless elapsed_time_string == ''

        puts PrettyBacon.color(:green, "#{spaces}✓ ") + "#{@description}" + elapsed_time_string
      end
    end

    #:nodoc:
    def handle_summary
      print ErrorLog  if Backtraces
      unless Counter[:disabled].zero?
        puts PrettyBacon.color(:yellow, "#{Counter[:disabled]} disabled specifications\n")
      end
      puts "%d specifications (%d requirements), %d failures, %d errors" %
        Counter.values_at(:specifications, :requirements, :failed, :errors)
    end

    #:nodoc:
    def spaces
      return '  ' * (@specs_depth || 0)
    end
  end

  module SpecDoxOutput
    attr_accessor :running_disabled_spec
  end

  module TapOutput
    attr_accessor :running_disabled_spec
  end

  Outputs['pretty_spec_dox'] = PrettySpecDoxOutput
end
