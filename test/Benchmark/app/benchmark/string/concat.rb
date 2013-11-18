def string_concat(x)
  ascii = "hello"
  utf8  = "こんにちは"
  long_string = "The quick brown fox jumps over the lazy dog."

  x.report "interpolation with ASCII" do
    100000.times do
      "#{ascii} #{ascii} #{ascii}"
    end
  end

  x.report "interpolation with UTF8" do
    100000.times do
      "#{utf8} #{utf8} #{utf8}"
    end
  end

  x.report "interpolation with long" do
    100000.times do
      "#{long_string} #{long_string} #{long_string}"
    end
  end

  x.report "+ with ASCII" do
    100000.times do
      ascii + ascii + ascii
    end
  end

  x.report "+ with UTF8" do
    100000.times do
      utf8 + utf8 + utf8
    end
  end

  x.report "+ with long" do
    100000.times do
      long_string + long_string + long_string
    end
  end

  x.report "<< with ASCII" do
    100000.times do
      str = ascii.dup
      str << str << str
    end
  end

  x.report "<< with UTF8" do
    100000.times do
      str = utf8.dup
      str << str << str
    end
  end

  x.report "<< with long" do
    100000.times do
      str = long_string.dup
      str << str << str
    end
  end

  x.report "concat with ASCII" do
    100000.times do
      str = ascii.dup
      str.concat(str).concat(str)
    end
  end

  x.report "concat with UTF8" do
    100000.times do
      str = utf8.dup
      str.concat(str).concat(str)
    end
  end

  x.report "concat with long" do
    100000.times do
      str = long_string.dup
      str.concat(str).concat(str)
    end
  end

  x.report "* with ASCII" do
    100000.times do
      ascii * 10
    end
  end

  x.report "* with UTF8" do
    100000.times do
      utf8 * 10
    end
  end

  x.report "* with long" do
    100000.times do
      long_string * 10
    end
  end
end
