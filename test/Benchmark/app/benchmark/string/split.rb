def string_split(x)
  string = "aaaa|bbbbbbbbbbbbbbbbbbbbbbbbbbbb|cccccccccccccccccccccccccccccccccccc|dd|eeeeeeeeeeeeeeeeeeeeeeeeeeeeeee|ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff|gggggggggggggggggggggggggggggggggggggggggggggggggggg|hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh|i|j|k|l|m|n|ooooooooooooooooooooooooo|"

  x.report "split(str) match" do
    10000.times do
      string.split('|')
    end
  end

  x.report "split(str, -1) match" do
    10000.times do
      string.split('|', -1)
    end
  end

  x.report "split(str) mismatch" do
    10000.times do
      string.split('.')
    end
  end

  x.report "split(regexp) match" do
    10000.times do
      string.split(/\|/)
    end
  end

  x.report "split(regexp) mismatch" do
    10000.times do
      string.split(/\./)
    end
  end

  irc_str = ":irc.malkier.net UID UqdTi59atgtYoV9NUKvE7qMOwG2Fl 1 1305135275 +x UqdTi59atgtYoV9NUKvE7qMOwG2Fl UqdTi59atgtYoV9NUKvE7qMOwG2Fl 127.0.0.1 XXX :fake omg"

  x.report "split(' ') with awk" do
    10000.times do
      irc_str.split(' ')
    end
  end

  newline_string = "string with newline\n" * 100

  x.report "split(regexp) with newline" do
    10000.times do
      newline_string.split(/\n/)
    end
  end

  no_newline_string = "string with newline" * 100

  x.report "split(regexp) with no newline" do
    10000.times do
      newline_string.split(/\n/)
    end
  end
end