# motion-stump/lib/stump/mock.rb
class Object
  def mock!(options = {}, &block)

    behavior =  if block_given?
                  lambda do |*args|

                    block.call(*args)
                  end
                elsif options[:yield]
                  lambda do |*args|
                    yield(options[:yield])
                  end
                else
                  lambda do |*args|
                    return options[:return]
                  end
                end
  end
end

describe "compile4_spec" do
  it "should work" do
    mock! { 42 }.call.should == 42
  end
end