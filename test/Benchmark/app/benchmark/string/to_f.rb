def string_to_f(x)
  small_int = "5"
  large_int = "14213542524"
  small_float = "5.0"
  large_float = "5415125422.0"

  x.report "to_f with small integer" do
    1000000.times do
      small_int.to_f
    end
  end

  x.report "to_f with large integer" do
    1000000.times do
      large_int.to_f
    end
  end

  x.report "to_f with small float" do
    1000000.times do
      small_float.to_f
    end
  end

  x.report "to_f with large float" do
    1000000.times do
      large_float.to_f
    end
  end
end
