def array_rotate(x)
  large_array = $large_array.dup

  x.report "rotate" do
    10000.times do
      large_array.rotate
    end
  end

  x.report "rotate(10)" do
    10000.times do
      large_array.rotate(10)
    end
  end

  x.report "rotate(-10)" do
    10000.times do
      large_array.rotate(-10)
    end
  end

  x.report "rotate!" do
    10000.times do
      large_array.rotate!
    end
  end

  x.report "rotate!(10)" do
    10000.times do
      large_array.rotate!(10)
    end
  end

  x.report "rotate!(-10)" do
    10000.times do
      large_array.rotate!(-10)
    end
  end
end