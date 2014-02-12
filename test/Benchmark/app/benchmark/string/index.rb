# -*- coding: utf-8 -*-
def string_index(x)
  string = "the"
  string_utf8 = "そして"
  regexp = /[aeiou](.)\1/
  offset = 90

  x.report "index(string) with ASCII" do
    100000.times do
      $short_sentence_ascii.index(string)
    end
  end

  x.report "index(string, pos) with ASCII" do
    100000.times do
      $short_sentence_ascii.index(string, offset)
    end
  end

  x.report "index(regexp) with ASCII" do
    100000.times do
      $short_sentence_ascii.index(regexp)
    end
  end

  x.report "index(regexp, pos) with ASCII" do
    100000.times do
      $short_sentence_ascii.index(regexp, offset)
    end
  end

  x.report "index(string) with UTF8" do
    100000.times do
      $short_sentence_utf8.index(string_utf8)
    end
  end

  x.report "index(string, pos) with UTF8" do
    100000.times do
      $short_sentence_utf8.index(string_utf8, offset)
    end
  end

  x.report "index(regexp) with UTF8" do
    100000.times do
      $short_sentence_utf8.index(regexp)
    end
  end

  x.report "index(regexp, pos) with UTF8" do
    100000.times do
      $short_sentence_utf8.index(regexp, offset)
    end
  end
end
