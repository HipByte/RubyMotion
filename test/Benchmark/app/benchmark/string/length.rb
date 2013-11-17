def string_length(x)
  x.report "length with ASCII" do
    1000000.times do
      $short_sentence_ascii.length
    end
  end

  x.report "length with UTF8" do
    1000000.times do
      $short_sentence_utf8.length
    end
  end
end
