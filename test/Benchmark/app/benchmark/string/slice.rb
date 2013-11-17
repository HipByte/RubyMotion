def string_slice(x)
  range = 34..40
  regexp = /[aeiou](.)\1/

  x.report "slice(num) with ASCII" do
    100000.times do
      $short_sentence_ascii.slice(42)
    end
  end

  x.report "slice(num) with UTF8" do
    100000.times do
      $short_sentence_utf8.slice(42)
    end
  end

  x.report "slice(num, num) with ASCII" do
    100000.times do
      $short_sentence_ascii.slice(42, 54)
    end
  end

  x.report "slice(num, num) with UTF8" do
    100000.times do
      $short_sentence_utf8.slice(42, 54)
    end
  end

  x.report "slice(range) with ASCII" do
    100000.times do
      $short_sentence_ascii.slice(range)
    end
  end

  x.report "slice(range) with UTF8" do
    100000.times do
      $short_sentence_utf8.slice(range)
    end
  end

  x.report "slice(regexp) with ASCII" do
    100000.times do
      $short_sentence_ascii.slice(regexp)
    end
  end

  x.report "slice(regexp) with UTF8" do
    100000.times do
      $short_sentence_utf8.slice(regexp)
    end
  end

  x.report "slice(str) with ASCII match" do
    100000.times do
      $short_sentence_ascii.slice("country")
    end
  end

  x.report "slice(str) with ASCII nomatch" do
    100000.times do
      $short_sentence_ascii.slice("abcdef")
    end
  end

  x.report "slice(str) with UTF8 match" do
    100000.times do
      $short_sentence_utf8.slice("しかし")
    end
  end

  x.report "slice(str) with UTF8 nomatch" do
    100000.times do
      $short_sentence_utf8.slice("あいうえお")
    end
  end
end