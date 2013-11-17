def string_new(x)
  ascii = "The quick brown fox jumps over the lazy dog."
  utf8  = "飛べねぇ豚はタダの豚だ...................."

  x.report "new with ASCII" do
    100000.times do
      String.new(ascii)
    end
  end

  x.report "new with UTF8" do
    100000.times do
      String.new(utf8)
    end
  end
end
