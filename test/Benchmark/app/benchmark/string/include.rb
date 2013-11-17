def string_include(x)
  x.report "include? with ASCII match" do
    100000.times do
      $short_sentence_ascii.include?("Candahar")
    end
  end

  x.report "include? with ASCII nomatch" do
    100000.times do
      $short_sentence_ascii.include?("abcde")
    end
  end

  x.report "include? with UTF8 match" do
    100000.times do
      $short_sentence_utf8.include?("ロンドン")
    end
  end

  x.report "include? with UTF8 nomatch" do
    100000.times do
      $short_sentence_utf8.include?("日本")
    end
  end
end
