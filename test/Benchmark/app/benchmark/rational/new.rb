def rational_new(x)
  x.report "Rational(x, y)" do
    200000.times do
      Rational(3, 2.5)
    end
  end

end
