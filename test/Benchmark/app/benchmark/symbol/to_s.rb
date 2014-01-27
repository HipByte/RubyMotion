def symbol_to_s(x)
  symbol = :"hello world"

  x.report "to_s" do
    1000000.times do
      symbol.to_s
    end
  end
end
