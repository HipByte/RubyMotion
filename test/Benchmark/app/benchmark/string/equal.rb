# -*- coding: utf-8 -*-
def string_equal(x)
  string_a = "#{'a' * 1_001}"
  first_char_different = "b#{'a' * 1_000}"
  last_char_different = "#{'a' * 1_000}b"
  same = string_a.dup
  utf8  = "あ" * 500

  x.report "== with match" do
    100000.times do
      string_a == same
    end
  end

  x.report "== with mismatch first char" do
    100000.times do
      string_a == first_char_different
    end
  end

  x.report "== with mismatch last char" do
    100000.times do
      string_a == last_char_different
    end
  end

  x.report "== with match UTF8" do
    utf8_same = utf8.dup
    100000.times do
      utf8 == utf8_same
    end
  end
end
