def rational_multiply(x)
  rat1 = Rational(3, 2.5)
  rat2 = Rational(3, 4)
  x.report "* Rational" do
    500000.times do
      rat1 * rat2
    end
  end

  x.report "* Fixnum" do
    500000.times do
      rat1 * 10
    end
  end

  x.report "* Float" do
    500000.times do
      rat1 * 4.5
    end
  end
end
