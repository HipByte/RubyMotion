# Bacon -- small RSpec clone.
#
# "Truth will sooner come out from error than from confusion." ---Francis Bacon
#
# Copyright (C) 2011 Eloy Durán eloy.de.enige@gmail.com
# Copyright (C) 2007 - 2011 Christian Neukirchen <purl.org/net/chneukirchen>
#
# Bacon is freely distributable under the terms of an MIT-style license.
# See COPYING or http://www.opensource.org/licenses/mit-license.php.

module Bacon
  VERSION = "1.3"

  Counter = Hash.new(0)
  ErrorLog = ""
  Shared = Hash.new { |_, name|
    raise NameError, "no such context: #{name.inspect}"
  }

  RestrictName    = //  unless defined? RestrictName
  RestrictContext = //  unless defined? RestrictContext

  Backtraces = true  unless defined? Backtraces

  module RubyMineOutput
    @@entered = false
    @@description = nil
    @@specification = nil
    @@started = nil

    def handle_specification_begin(name)
      unless @@entered
        puts "##teamcity[enteredTheMatrix timestamp = '#{time}']\n\n"
        @@entered = true
      end
      @@specification = name
      puts "##teamcity[testSuiteStarted timestamp = '#{time}' name = '#{escape_message(name)}']\n\n"
    end

    def handle_specification_end
      puts "##teamcity[testSuiteFinished timestamp = '#{time}' name = '#{escape_message(@@specification)}']\n\n" if Counter[:context_depth] == 1
    end

    def handle_requirement_begin(description)
      @@description = description
      @@started = Time.now
      puts "##teamcity[testStarted timestamp = '#{time}' captureStandardOutput = 'true' name = '#{escape_message(description)}']\n\n"
    end

    def handle_requirement_end(error)
      if !error.empty?
        puts "##teamcity[testFailed timestamp = '#{time}' message = '#{escape_message(error)}' name = '#{escape_message(@@description)}']\n\n"
      end
      duration = ((Time.now - @@started) * 1000).to_i
      puts "##teamcity[testFinished timestamp = '#{time}' duration = '#{duration}' name = '#{escape_message(@@description)}']\n\n"     
    end

    def handle_summary
      print ErrorLog if Backtraces
      puts "%d specifications (%d requirements), %d failures, %d errors" %
               Counter.values_at(:specifications, :requirements, :failed, :errors)
    end

    def spaces
      "  " * (Counter[:context_depth] - 1)
    end

    def time
      convert_time_to_java_simple_date(Time.now)
    end

    def escape_message(message)
      copy_of_text = String.new(message)

      copy_of_text.gsub!(/\|/, "||")

      copy_of_text.gsub!(/'/, "|'")
      copy_of_text.gsub!(/\n/, "|n")
      copy_of_text.gsub!(/\r/, "|r")
      copy_of_text.gsub!(/\]/, "|]")

      copy_of_text.gsub!(/\[/, "|[")

      begin
        copy_of_text.encode!('UTF-8') if copy_of_text.respond_to? :encode!
        copy_of_text.gsub!(/\u0085/, "|x") # next line
        copy_of_text.gsub!(/\u2028/, "|l") # line separator
        copy_of_text.gsub!(/\u2029/, "|p") # paragraph separator
      rescue
        # it is not an utf-8 compatible string :(
      end

      copy_of_text
    end   

    def convert_time_to_java_simple_date(time)
      gmt_offset = time.gmt_offset
      gmt_sign = gmt_offset < 0 ? "-" : "+"
      gmt_hours = gmt_offset.abs / 3600
      gmt_minutes = gmt_offset.abs % 3600

      millisec = time.usec == 0 ? 0 : time.usec / 1000

      #Time string in Java SimpleDateFormat
      sprintf("#{time.strftime("%Y-%m-%dT%H:%M:%S.")}%03d#{gmt_sign}%02d%02d", millisec, gmt_hours, gmt_minutes)
    end
  end

  module SpecDoxOutput
    def handle_specification_begin(name)
      puts spaces + name
    end

    def handle_specification_end
      puts if Counter[:context_depth] == 1
    end

    def handle_requirement_begin(description)
      print "#{spaces}  - #{description}"
    end

    def handle_requirement_end(error)
      puts error.empty? ? "" : " [#{error}]"
    end

    def handle_summary
      print ErrorLog  if Backtraces
      puts "%d specifications (%d requirements), %d failures, %d errors" %
        Counter.values_at(:specifications, :requirements, :failed, :errors)
    end

    def spaces
      "  " * (Counter[:context_depth] - 1)
    end
  end

  module TestUnitOutput
    def handle_specification_begin(name); end
    def handle_specification_end        ; end

    def handle_requirement_begin(description) end
    def handle_requirement_end(error)
      if error.empty?
        print "."
      else
        print error[0..0]
      end
    end

    def handle_summary
      puts "", "Finished in #{Time.now - @timer} seconds."
      puts ErrorLog  if Backtraces
      puts "%d tests, %d assertions, %d failures, %d errors" %
        Counter.values_at(:specifications, :requirements, :failed, :errors)
    end
  end

  module FastOutput
    def handle_specification_begin(name); end
    def handle_specification_end; end

    def handle_requirement_begin(description); end
    def handle_requirement_end(error)
      return if error.empty?
      print error[0..0]
    end

    def handle_summary
      puts "", "Finished in #{Time.now - @timer} seconds."
      puts ErrorLog  if Backtraces
      puts "%d tests, %d assertions, %d failures, %d errors" %
        Counter.values_at(:specifications, :requirements, :failed, :errors)
    end
  end

  module TapOutput
    def handle_specification_begin(name); end
    def handle_specification_end        ; end

    def handle_requirement_begin(description)
      @description = description
      ErrorLog.replace ""
    end

    def handle_requirement_end(error)
      if error.empty?
        puts "ok %-3d - %s" % [Counter[:specifications], @description]
      else
        puts "not ok %d - %s: %s" %
          [Counter[:specifications], @description, error]
        puts ErrorLog.strip.gsub(/^/, '# ')  if Backtraces
      end
    end

    def handle_summary
      puts "1..#{Counter[:specifications]}"
      puts "# %d tests, %d assertions, %d failures, %d errors" %
        Counter.values_at(:specifications, :requirements, :failed, :errors)
    end
  end

  module KnockOutput
    def handle_specification_begin(name); end
    def handle_specification_end        ; end

    def handle_requirement_begin(description)
      @description = description
      ErrorLog.replace ""
    end

    def handle_requirement_end(error)
      if error.empty?
        puts "ok - %s" % [@description]
      else
        puts "not ok - %s: %s" % [@description, error]
        puts ErrorLog.strip.gsub(/^/, '# ')  if Backtraces
      end
    end

    def handle_summary;  end
  end

  Outputs = {
    'spec_dox' => SpecDoxOutput,
    'fast' => FastOutput,
    'test_unit' => TestUnitOutput,
    'tap' => TapOutput,
    'knock' => KnockOutput,
    'rubymine' => RubyMineOutput
  }
  extend(Outputs[ENV['output']] || SpecDoxOutput)

  class Error < RuntimeError
    attr_accessor :count_as

    def initialize(count_as, message)
      @count_as = count_as
      super message
    end
  end

  class Specification
    attr_reader :description

    def initialize(context, description, block, before_filters, after_filters)
      @context, @description, @block = context, description, block
      @before_filters, @after_filters = before_filters.dup, after_filters.dup

      @postponed_blocks_count = 0
      @ran_spec_block = false
      @ran_after_filters = false
      @exception_occurred = false
      @error = ""
    end

    def postponed?
      @postponed_blocks_count != 0
    end

    def run_before_filters
      execute_block { @before_filters.each { |f| @context.instance_eval(&f) } }
    end

    def run_spec_block
      @ran_spec_block = true
      # If an exception occurred, we definitely don't need to perform the actual spec anymore
      unless @exception_occurred
        execute_block { @context.instance_eval(&@block) }
      end
      finish_spec unless postponed?
    end

    def run_after_filters
      @ran_after_filters = true
      execute_block { @after_filters.each { |f| @context.instance_eval(&f) } }
    end

    def run
      Bacon.handle_requirement_begin(@description)
      Counter[:depth] += 1
      run_before_filters
      @number_of_requirements_before = Counter[:requirements]
      run_spec_block unless postponed?
    end

    def schedule_block(seconds, &block)
      # If an exception occurred, we definitely don't need to schedule any more blocks
      unless @exception_occurred
        @postponed_blocks_count += 1
        performSelector("run_postponed_block:", withObject:block, afterDelay:seconds)
      end
    end

    def postpone_block(timeout = 1, &block)
      # If an exception occurred, we definitely don't need to schedule any more blocks
      unless @exception_occurred
        if @postponed_block
          raise "Only one indefinite `wait' block at the same time is allowed!"
        else
          @postponed_blocks_count += 1
          @postponed_block = block
          performSelector("postponed_block_timeout_exceeded", withObject:nil, afterDelay:timeout)
        end
      end
    end

    def postpone_block_until_change(object_to_observe, key_path, timeout = 1, &block)
      # If an exception occurred, we definitely don't need to schedule any more blocks
      unless @exception_occurred
        if @postponed_block
          raise "Only one indefinite `wait' block at the same time is allowed!"
        else
          @postponed_blocks_count += 1
          @postponed_block = block
          @observed_object_and_key_path = [object_to_observe, key_path]
          object_to_observe.addObserver(self, forKeyPath:key_path, options:0, context:nil)
          performSelector("postponed_change_block_timeout_exceeded", withObject:nil, afterDelay:timeout)
        end
      end
    end

    def observeValueForKeyPath(key_path, ofObject:object, change:_, context:__)
      resume
    end

    def postponed_change_block_timeout_exceeded
      remove_observer!
      postponed_block_timeout_exceeded
    end

    def remove_observer!
      if @observed_object_and_key_path
        object, key_path = @observed_object_and_key_path
        object.removeObserver(self, forKeyPath:key_path)
        @observed_object_and_key_path = nil
      end
    end

    def postponed_block_timeout_exceeded
      cancel_scheduled_requests!
      execute_block { raise Error.new(:failed, "timeout exceeded: #{@context.name} - #{@description}") }
      @postponed_blocks_count = 0
      finish_spec
    end

    def resume
      NSObject.cancelPreviousPerformRequestsWithTarget(self, selector:'postponed_block_timeout_exceeded', object:nil)
      NSObject.cancelPreviousPerformRequestsWithTarget(self, selector:'postponed_change_block_timeout_exceeded', object:nil)
      remove_observer!
      block, @postponed_block = @postponed_block, nil
      run_postponed_block(block)
    end

    def run_postponed_block(block)
      # If an exception occurred, we definitely don't need execute any more blocks
      execute_block(&block) unless @exception_occurred
      @postponed_blocks_count -= 1
      unless postponed?
        if @ran_after_filters
          exit_spec
        elsif @ran_spec_block
          finish_spec
        else
          run_spec_block
        end
      end
    end

    def finish_spec
      if !@exception_occurred && Counter[:requirements] == @number_of_requirements_before
        # the specification did not contain any requirements, so it flunked
        execute_block { raise Error.new(:missing, "empty specification: #{@context.name} #{@description}") }
      end
      run_after_filters
      exit_spec unless postponed?
    end

    def cancel_scheduled_requests!
      NSObject.cancelPreviousPerformRequestsWithTarget(@context)
      NSObject.cancelPreviousPerformRequestsWithTarget(self)
    end

    def exit_spec
      cancel_scheduled_requests!
      Counter[:depth] -= 1
      Bacon.handle_requirement_end(@error)
      @context.specification_did_finish(self)
    end

    def execute_block
      begin
        yield
      rescue Object => e
        @exception_occurred = true

        ErrorLog << "#{e.class}: #{e.message}\n"
        lines = $DEBUG ? e.backtrace : e.backtrace.find_all { |line| line !~ /bin\/macbacon|\/mac_bacon\.rb:\d+/ }
        lines.each_with_index { |line, i|
          ErrorLog << "\t#{line}#{i==0 ? ": #{@context.name} - #{@description}" : ""}\n"
        }
        ErrorLog << "\n"

        @error = if e.kind_of? Error
          Counter[e.count_as] += 1
          e.count_as.to_s.upcase
        else
          Counter[:errors] += 1
          "ERROR: #{e.class}"
        end
      end
    end
  end

  def self.add_context(context)
    (@contexts ||= []) << context
  end

  def self.current_context_index
    @current_context_index ||= 0
  end

  def self.current_context
    @contexts[current_context_index]
  end

  def self.run
    @timer ||= Time.now
    Counter[:context_depth] += 1
    handle_specification_begin(current_context.name)
    current_context.performSelector("run", withObject:nil, afterDelay:0)
  end

  def self.context_did_finish(context)
    handle_specification_end
    Counter[:context_depth] -= 1
    if (@current_context_index + 1) < @contexts.size
      @current_context_index += 1
      run
    else
      # DONE
      handle_summary
      exit(Counter.values_at(:failed, :errors).inject(:+))
    end
  end

  class Context
    attr_reader :name, :block
    
    def initialize(name, before = nil, after = nil, &block)
      @name = name
      @before, @after = (before ? before.dup : []), (after ? after.dup : [])
      @block = block
      @specifications = []
      @current_specification_index = 0

      Bacon.add_context(self)

      instance_eval(&block)
    end

    def run
      # TODO
      #return  unless name =~ RestrictContext
      if spec = current_specification
        spec.performSelector("run", withObject:nil, afterDelay:0)
      else
        Bacon.context_did_finish(self)
      end
    end

    def current_specification
      @specifications[@current_specification_index]
    end

    def specification_did_finish(spec)
      if (@current_specification_index + 1) < @specifications.size
        @current_specification_index += 1
        run
      else
        Bacon.context_did_finish(self)
      end
    end

    def before(&block); @before << block; end
    def after(&block);  @after << block; end

    def behaves_like(*names)
      names.each { |name| instance_eval(&Shared[name]) }
    end

    def it(description, &block)
      return  unless description =~ RestrictName
      block ||= lambda { should.flunk "not implemented" }
      Counter[:specifications] += 1
      @specifications << Specification.new(self, description, block, @before, @after)
    end
    
    def should(*args, &block)
      if Counter[:depth]==0
        it('should '+args.first,&block)
      else
        super(*args,&block)
      end
    end

    def describe(*args, &block)
      context = Bacon::Context.new(args.join(' '), @before, @after, &block)
      (parent_context = self).methods(false).each {|e|
        class<<context; self end.send(:define_method, e) {|*args| parent_context.send(e, *args)}
      }
      context
    end

    def wait(seconds = nil, &block)
      if seconds
        current_specification.schedule_block(seconds, &block)
      else
        current_specification.postpone_block(&block)
      end
    end

    def wait_max(timeout, &block)
      current_specification.postpone_block(timeout, &block)
    end

    def wait_for_change(object_to_observe, key_path, timeout = 1, &block)
      current_specification.postpone_block_until_change(object_to_observe, key_path, timeout, &block)
    end

    def resume
      current_specification.resume
    end

    def raise?(*args, &block); block.raise?(*args); end
    def throw?(*args, &block); block.throw?(*args); end
    def change?(*args, &block); block.change?(*args); end
  end
end


class Object
  def true?; false; end
  def false?; false; end
end

class TrueClass
  def true?; true; end
end

class FalseClass
  def false?; true; end
end

class Proc
  def raise?(*exceptions)
    call
  rescue *(exceptions.empty? ? RuntimeError : exceptions) => e
    e
  else
    false
  end

  def throw?(sym)
    catch(sym) {
      call
      return false
    }
    return true
  end

  def change?
    pre_result = yield
    called = call
    post_result = yield
    pre_result != post_result
  end
end

class Numeric
  def close?(to, delta)
    (to.to_f - self).abs <= delta.to_f  rescue false
  end
end


class Object
  def should(*args, &block)    Should.new(self).be(*args, &block)         end
end

module Kernel
  private
  def describe(*args, &block) Bacon::Context.new(args.join(' '), &block)  end
  def shared(name, &block)    Bacon::Shared[name] = block                 end
end

class Should
  # Kills ==, ===, =~, eql?, equal?, frozen?, instance_of?, is_a?,
  # kind_of?, nil?, respond_to?, tainted?
  instance_methods.each { |name| undef_method name  if name =~ /\?|^\W+$/ }

  def initialize(object)
    @object = object
    @negated = false
  end

  def not(*args, &block)
    @negated = !@negated

    if args.empty?
      self
    else
      be(*args, &block)
    end
  end

  def be(*args, &block)
    if args.empty?
      self
    else
      block = args.shift  unless block_given?
      satisfy(*args, &block)
    end
  end

  alias a  be
  alias an be

  def satisfy(*args, &block)
    if args.size == 1 && String === args.first
      description = args.shift
    else
      description = ""
    end

    r = yield(@object, *args)
    if Bacon::Counter[:depth] > 0
      Bacon::Counter[:requirements] += 1
      raise Bacon::Error.new(:failed, description)  unless @negated ^ r
      r
    else
      @negated ? !r : !!r
    end
  end

  def method_missing(name, *args, &block)
    name = "#{name}?"  if name.to_s =~ /\w[^?]\z/

    desc = @negated ? "not " : ""
    desc << @object.inspect << "." << name.to_s
    desc << "(" << args.map{|x|x.inspect}.join(", ") << ") failed"

    satisfy(desc) { |x| x.__send__(name, *args, &block) }
  end

  def equal(value)         self == value      end
  def match(value)         self =~ value      end
  def identical_to(value)  self.equal? value  end
  alias same_as identical_to

  def flunk(reason="Flunked")
    raise Bacon::Error.new(:failed, reason)
  end
end

# Do not log all exceptions when running the specs.
Exception.log_exceptions = false
