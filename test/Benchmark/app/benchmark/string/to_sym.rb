def string_to_sym(x)
  string = "x" * 30

  x.report "to_sym" do
    1000000.times do
      string.to_sym
    end
  end
end
