# -*- coding: utf-8 -*-
def string_match(x)
  x.report "=~ with ASCII" do
    100000.times do
      "hello world" =~ /lo/
    end
  end

  x.report "=~ with UTF8" do
    100000.times do
      "あいうえお" =~ /うえ/
    end
  end

  x.report "=~ with dynamic regexp" do
    str = "lo"
    50000.times do
      "hello world" =~ /#{str}/
    end
  end
end
