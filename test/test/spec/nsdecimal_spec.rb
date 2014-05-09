describe "NSDecimal" do
  xit "can be created from NSDecimalNumber" do
    dn = NSDecimalNumber.decimalNumberWithString('123.456')
    d = dn.decimalValue
    d.class.should == NSDecimal
    NSDecimalNumber.decimalNumberWithDecimal(d).should == dn
    ptr = Pointer.new(NSDecimal.type)
    ptr[0] = d
    NSDecimalString(ptr, nil).should == dn.stringValue
  end
end

describe 'BigDecimal' do
  it 'is an alias for NSDecimalNumber' do
    BigDecimal.should == NSDecimalNumber
  end

  it 'can be created with a string' do
    bd = BigDecimal.new('  0.123456789123456789END')
    #bd = BigDecimal.new('0.123456789123456789')
    bd.class.should == BigDecimal
    bd.inspect.should == '0.123456789123456789'
  end

  xit 'can be created with an integer' do
    bd = BigDecimal.new(42)
    bd.class.should == BigDecimal
    bd.inspect.should == '42'
  end

  xit 'can be created with a float' do
    bd = BigDecimal.new(0.1)
    bd.class.should == BigDecimal
    bd.inspect.should == '0.1'
  end

  xit 'can be created with a BigDecimal' do
    bd = BigDecimal.new(BigDecimal.new(42))
    bd.class.should == BigDecimal
    bd.inspect.should == '42'
  end

  it 'returns whether or not it is zero' do
    BigDecimal.new('0.00000000000000000').should.be.zero
    BigDecimal.new('0.00000000000000000').should.not.be.nonzero
    BigDecimal.new('0.00000000000000001').should.be.nonzero
    BigDecimal.new('0.00000000000000001').should.not.be.zero
  end

  it 'returns whether or not is a number' do
    (BigDecimal.new('0') / BigDecimal.new('0')).should.be.nan
    (BigDecimal.new('1') / BigDecimal.new('1')).should.not.be.nan
  end

  it 'returns wether or not it is infinite' do
    (BigDecimal.new('1') / BigDecimal.new('0')).infinite?.should == 1
    (BigDecimal.new('-1') / BigDecimal.new('0')).infinite?.should == -1
    (BigDecimal.new('1') / BigDecimal.new('1')).infinite?.should == nil
  end

  it 'returns wether or not it is finite' do
    (BigDecimal.new('1') / BigDecimal.new('1')).should.be.finite
    # NaN
    (BigDecimal.new('0') / BigDecimal.new('0')).should.not.be.finite
    # Infinity
    (BigDecimal.new('1') / BigDecimal.new('0')).should.not.be.finite
    (BigDecimal.new('-1') / BigDecimal.new('0')).should.not.be.finite
  end

  it 'can sum' do
    sum = BigDecimal.new('0')
    10000.times do
      sum = sum + BigDecimal.new('0.0001')
    end
    sum.inspect.should == '1'
  end

  it 'can subtract' do
    sum = BigDecimal.new('1')
    10000.times do
      sum = sum - BigDecimal.new('0.0001')
    end
    sum.inspect.should == '0'
  end

  it 'can multiply' do
    sum = BigDecimal.new('0.0001')
    10.times do
      sum = sum * BigDecimal.new('2')
    end
    sum.inspect.should == '0.1024'
  end

  it 'can divide' do
    sum = BigDecimal.new('0.1024')
    10.times do
      sum = sum / BigDecimal.new('2')
    end
    sum.inspect.should == '0.0001'
  end

  it 'can raise to the power N' do
    (BigDecimal.new('0.0003') ** 2).inspect.should == '0.00000009'
  end

  it 'is comparable' do
    low  = BigDecimal.new('0.0000001')
    high = BigDecimal.new('0.0000002')

    low.should == low
    low.should != high

    low.should >= low
    low.should <= low

    low.should <= high
    high.should >= low

    low.should < high
    high.should > low
  end

  it 'can be passed to Objective-C APIs transperantly' do
    string = '0.123456789123456789'
    formatter = NSNumberFormatter.new
    formatter.alwaysShowsDecimalSeparator = true
    formatter.minimumIntegerDigits = 1
    formatter.minimumFractionDigits = string.split('.').last.length

    formatter.stringFromNumber(BigDecimal.new(string)).should == string
  end

  # TODO when we receive a number from an Objective-C API we must
  #      ensure to keep it a NSDecimalNumber
  xit 'can be passed from Objective-C APIs transperantly' do
    string = '0.123456789123456789'
    formatter = NSNumberFormatter.new
    formatter.generatesDecimalNumbers = true
    formatter.numberFromString(string).should == BigDecimal.new(string)
  end
end
