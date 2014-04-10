#module ArraySpec
  class ArraySpecSplat < Java::Lang::Object
    def unpack_3args(a, b, c)
      [a, b, c]
    end

    def unpack_4args(a, b, c, d)
      [a, b, c, d]
    end
  end
#end
