# motion-state-machine/spec/transition_spec.rb
module StateMachine
  class Transition
    def initialize(options)
      @options = options.dup
    end
  end
end

describe "compile3_spec" do
  before do
    @options = {
      state_machine: @state_machine,
      from: :awake,
      to: :tired,
      on: :work_done
    }
    @transition = StateMachine::Transition.new @options
  end

  it "should work" do
    #  :unless  :if     allowed?
    {
      [nil,     nil]    => true,
      [nil,     false]  => false,
      [nil,     true]   => true,
      [false,   nil]    => true,
      [false,   false]  => false,
      [false,   true]   => true,
      [true,    nil]    => false,
      [true,    false]  => false,
      [true,    true]   => false,
    }.each do |guards, result|
      transition = StateMachine::Transition.new @options.dup
      # transition.options[:unless] = proc {guards[0]} unless guards[0].nil?
      # transition.options[:if]     = proc {guards[1]} unless guards[1].nil?
    end

    1.should == 1
  end
end
