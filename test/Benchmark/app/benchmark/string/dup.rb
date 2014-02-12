# -*- coding: utf-8 -*-
def string_dup(x)
  ascii = "The quick brown fox jumps over the lazy dog."
  utf8  = "飛べねぇ豚はタダの豚だ...................."

  x.report "dup with ASCII" do
    100000.times do
      ascii.dup
    end
  end

  x.report "dup with UTF8" do
    100000.times do
      utf8.dup
    end
  end
end
