def string_reverse(x)
  x.report "reverse with ASCII" do
    100000.times do
      $short_sentence_ascii.reverse
    end
  end

  x.report "reverse! with ASCII" do
    100000.times do
      str = $short_sentence_ascii.dup
      str.reverse!
    end
  end

  x.report "reverse with UTF8" do
    100000.times do
      $short_sentence_utf8.reverse
    end
  end

  x.report "reverse! with UTF8" do
    100000.times do
      str = $short_sentence_utf8.dup
      str.reverse!
    end
  end
end
