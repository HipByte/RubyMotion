def string_chomp(x)
  multiple_eol = "The quick brown fox jumps over the lazy dog.\r\n\r\n\n\n\r\n"
  no_eol       = "The quick brown fox jumps over the lazy dog."
  multiple_lf  = "The quick brown fox jumps over the lazy dog.\n\n\n\n\n\n"
  empty_string = ""
  utf8_string  = "飛べねぇ豚はタダの豚だ....................\r\n\r\n\n\n\r\n"


  x.report "chomp with multiple EOL" do
    100000.times do
      multiple_eol.chomp
    end
  end

  x.report "chomp with no EOL" do
    100000.times do
      no_eol.chomp
    end
  end

  x.report "chomp with multiple LF" do
    100000.times do
      multiple_lf.chomp
    end
  end

  x.report "chomp with empty string" do
    100000.times do
      empty_string.chomp
    end
  end

  x.report "chomp with UTF8 string" do
    100000.times do
      utf8_string.chomp
    end
  end

  x.report "chomp! with multiple EOL" do
    100000.times do
      multiple_eol.dup.chomp!
    end
  end

  x.report "chomp! with no EOL" do
    100000.times do
      no_eol.dup.chomp!
    end
  end

  x.report "chomp! with multiple LF" do
    100000.times do
      multiple_lf.dup.chomp!
    end
  end

  x.report "chomp! with empty string" do
    100000.times do
      empty_string.dup.chomp!
    end
  end

  x.report "chomp! with UTF8 string" do
    100000.times do
      utf8_string.dup.chomp!
    end
  end
end
