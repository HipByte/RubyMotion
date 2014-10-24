osx_10_10 = OSX_VERSION == '10.10'

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
  describe 'concerning initialization' do
    it 'can be created with a string and ignores space and unexpected input' do
      bd = BigDecimal.new('  0.123456789123456789END')
      bd.class.should == BigDecimal
      bd.inspect.should == '0.123456789123456789'
    end

    it 'can be created with an integer' do
      bd = BigDecimal.new(42)
      bd.class.should == BigDecimal
      bd.inspect.should == '42'
    end unless osx_10_10 # FIXME

    it 'can be created with a float' do
      should.not.raise TypeError do
        BigDecimal.new(0.1)
      end

      # Use 0.0 here because it's the only Float we can trust to not lose precision.
      number = 0.0
      number.class.should == Float
      bd = BigDecimal.new(number)
      bd.class.should == BigDecimal
      bd.inspect.should == '0'
    end unless osx_10_10 # FIXME

    it 'can be created with a Bignum' do
      number = NSIntegerMax
      number.class.should == Bignum
      bd = BigDecimal.new(number)
      bd.class.should == BigDecimal
      bd.inspect.should == number.to_s
    end

    it 'can be created with a BigDecimal' do
      bd = BigDecimal.new(BigDecimal.new(42))
      bd.class.should == BigDecimal
      bd.inspect.should == '42'
    end unless osx_10_10 # FIXME

    it 'can be created from any object that can coerce to a String' do
      o = Object.new
      def o.to_str; '0.1'; end
      bd = BigDecimal.new(o)
      bd.class.should == BigDecimal
      bd.inspect.should == '0.1'
    end unless osx_10_10 # FIXME

    # TODO leads to segfault on OS X 32bit
    it 'raises in case a BigDecimal cannot be created from the given object', :unless => (osx? && bits == 32) do
      should.raise TypeError do
        BigDecimal.new(Object.new)
      end
    end
  end

  it 'is an alias for NSDecimalNumber' do
    BigDecimal.should == NSDecimalNumber
  end

  describe 'concerning predicate methods' do
    it 'returns whether or not it is zero' do
      BigDecimal.new('0.00000000000000000').should.be.zero
      BigDecimal.new('0.00000000000000000').should.not.be.nonzero
      BigDecimal.new('0.00000000000000001').should.be.nonzero
      BigDecimal.new('0.00000000000000001').should.not.be.zero
    end

    it 'returns whether or not is a number' do
      (BigDecimal.new('0') / 0).should.be.nan
      (BigDecimal.new('1') / 1).should.not.be.nan
    end unless osx_10_10 # FIXME

    it 'returns wether or not it is infinite' do
      (BigDecimal.new('1') / 0).infinite?.should == 1
      (BigDecimal.new('-1') / 0).infinite?.should == -1
      (BigDecimal.new('1') / 1).infinite?.should == nil
    end

    it 'returns wether or not it is finite' do
      (BigDecimal.new('1') / 1).should.be.finite
      # NaN
      (BigDecimal.new('0') / 0).should.not.be.finite
      # Infinity
      (BigDecimal.new('1') / 0).should.not.be.finite
      (BigDecimal.new('-1') / 0).should.not.be.finite
    end unless osx_10_10 # FIXME
  end

  describe 'concerning operators' do
    it 'can sum' do
      sum = BigDecimal.new(0.0)
      10000.times do
        sum = sum + BigDecimal.new('0.0001')
      end
      sum.should == 1
    end

    it 'can subtract' do
      sum = BigDecimal.new(1)
      10000.times do
        sum = sum - BigDecimal.new('0.0001')
      end
      sum.should == 0.0
    end

    it 'can multiply' do
      sum = BigDecimal.new('0.0001')
      10.times do
        sum = sum * 2
      end
      sum.inspect.should == '0.1024'
    end unless osx_10_10 # FIXME

    it 'can divide' do
      sum = BigDecimal.new('0.1024')
      10.times do
        sum = sum / 2
      end
      sum.inspect.should == '0.0001'
    end unless osx_10_10 # FIXME

    it 'can raise to the power N' do
      (BigDecimal.new('0.0003') ** 2).inspect.should == '0.00000009'
    end

    it 'can raise to the power -N' do
      (BigDecimal.new('2') ** -3).inspect.should == '0.125'
    end unless osx_10_10 # FIXME

    it 'can perform a modulo operation' do
      (BigDecimal.new('0.1') % '0.2').should == '0.1'
      (BigDecimal.new('0.2') % '0.2').should == 0
      (BigDecimal.new('0.3') % '0.2').should == '0.1'
      (BigDecimal.new('-0.1') % '-0.2').should == '-0.1'
      (BigDecimal.new('-0.2') % '-0.2').should == -0
      (BigDecimal.new('-0.3') % '-0.2').should == '-0.1'
      (BigDecimal.new('0.1') % '-1').should == '-0.9'
      (BigDecimal.new('-0.1') % '1').should == '0.9'
    end unless osx_10_10 # FIXME

    it 'returns the absolute value' do
      BigDecimal.new(5).abs.should == 5
      BigDecimal.new(-5).abs.should == 5
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
    end unless osx_10_10 # FIXME
  end

  describe 'concerning (Objective-)C interoperability' do
    it 'can be passed to Objective-C APIs transperantly' do
      string = '0.123456789123456789'
      formatter = NSNumberFormatter.new
      formatter.alwaysShowsDecimalSeparator = true
      formatter.minimumIntegerDigits = 1
      formatter.minimumFractionDigits = string.split('.').last.length

      formatter.stringFromNumber(BigDecimal.new(string)).should == string
    end

    it 'can be passed from Objective-C APIs transperantly' do
      string = '0.123456789123456789'
      NSDecimalNumber.decimalNumberWithString(string).should == BigDecimal.new(string)
    end

    it 'converts NSDecimal to BigDecimal' do
      string = '0.123456789123456789'
      value = NSDecimalNumber.decimalNumberWithString(string).decimalValue
      value.class.should == BigDecimal
      value.inspect.should == string
    end

    it 'converts BigDecimal to NSDecimal' do
      string = '0.123456789123456789'
      number = NSDecimalNumber.decimalNumberWithDecimal(BigDecimal.new(string))
      number.description.should == string
    end

    it 'converts BigDecimal to a pointer to NSDecimal' do
      string = '0.123456789123456789'
      NSDecimalString(BigDecimal.new(string), NSLocale.currentLocale).should == string
    end
  end

  describe 'NSJSONSerialization.JSONObjectWithData' do
    it 'should return 0.0 as Float' do
      # RM-511
      json = "{\"value\": 0.0}"
      opts = NSJSONReadingMutableContainers | NSJSONReadingMutableLeaves | NSJSONReadingAllowFragments
      result = NSJSONSerialization.JSONObjectWithData(json.to_data, options: opts, error: nil)
      result['value'].should == 0.0
      result['value'].class.should == Float
    end
  end
end
