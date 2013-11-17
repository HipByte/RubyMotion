def string_to_i(x)
  small_int = "5"
  large_int = "14213542524"
  small_float = "5.0"
  large_float = "5415125422.0"

  x.report "to_i with small integer" do
    1000000.times do
      small_int.to_i
    end
  end

  x.report "to_i with large integer" do
    1000000.times do
      large_int.to_i
    end
  end

  x.report "to_i with small float" do
    1000000.times do
      small_float.to_i
    end
  end

  x.report "to_i with large float" do
    1000000.times do
      large_float.to_i
    end
  end
end
