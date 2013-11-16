def array_dup(x)
  strings = ('a'..'z').to_a
  numbers = [-4, -81, 0, 5, 12, -1_000_000, 1, 10, 100, 1000]

  x.report "dup strings" do
    100000.times do |i|
      strings.dup
    end
  end

  x.report "dup numbers" do
    100000.times do |i|
      numbers.dup
    end
  end
end
