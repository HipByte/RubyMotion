def string_gsub(x)
  string = "2011-Mar-08T10:09:08.467"
  # para_string is 2000 characters, containing only 11 digits (in 3 \d+ matches)
  para_string = "What is Lorem Ipsum?\n" +
                  "Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book. It has survived not only five centuries, but also the leap into electronic typesetting, remaining essentially unchanged. It was popularised in the 1960s with the release of Letraset sheets containing Lorem Ipsum passages, and more recently with desktop publishing software like Aldus PageMaker including versions of Lorem Ipsum.\n" +
                  "Why do we use it?\n" +
                  "It is a long established fact that a reader will be distracted by the readable content of a page when looking at its layout. The point of using Lorem Ipsum is that it has a more-or-less normal distribution of letters, as opposed to using 'Content here, content here', making it look like readable English. Many desktop publishing packages and web page editors now use Lorem Ipsum as their default model text, and a search for 'lorem ipsum' will uncover many web sites still in their infancy. Various versions have evolved over the years, sometimes by accident, sometimes on purpose (injected humour and the like).\n" +
                  "Where can I get some?\n" +
                  "There are many variations of passages of Lorem Ipsum available, but the majority have suffered alteration in some form, by injected humour, or randomised words which don't look even slightly believable. If you are going to use a passage of Lorem Ipsum, you need to be sure there isn't anything embarrassing hidden in the middle of text. All the Lorem Ipsum generators on the Internet tend to repeat predefined chunks as necessary, making this the first true generator on the Internet. It uses a dictionary of over 200 Latin words, combined with a handful of model sentence structures, to generate Lorem Ipsum which looks reasonable. The generated Lorem Ipsum is therefore always free from repetition, injected humour, or non-characteristic words etc."

  x.report "gsub" do
    100.times do
      string.gsub(/[^-+',.\/:@[:alnum:]\[\]\x80-\xff]+/n, ' ')
    end
  end

  x.report "gsub!" do
    100.times do
      string.gsub!(/[^-+',.\/:@[:alnum:]\[\]\x80-\xff]+/n, ' ')
    end
  end

  x.report "gsub single character" do
    100.times do
      para_string.gsub(/./, 'X')
    end
  end

  x.report "gsub! single character" do
    para_string2 = para_string.dup
    100.times do
      para_string2.gsub(/./, 'X')
    end
  end

  x.report "gsub to shorter size" do
    100.times do
      para_string.gsub(/\w{9,}/, 'X')
    end
  end

  x.report "gsub! to shorter size" do
    para_string2 = para_string.dup
    100.times do
      para_string2.gsub!(/\w{9,}/, 'X')
    end
  end

  x.report "gsub to longer size" do
    100.times do
      para_string.gsub(/\w{9,}/, '\0and9chars')
    end
  end

  x.report "gsub! to longer size" do
    para_string2 = para_string.dup
    100.times do
      para_string2.gsub!(/\w{9,}/, '\0and9chars')
    end
  end

  x.report "sparse gsub" do
    100.times do
      para_string.gsub(/\d+/, '#')
    end
  end

  x.report "sparse gsub!" do
    para_string2 = para_string.dup
    100.times do
      para_string2.gsub!(/\d+/, '#')
    end
  end

  x.report "gsub, giving a block" do
    100.times do
      para_string.gsub(/\w+/) { |m| m+m.size.to_s }
    end
  end

  x.report "gsub!, giving a block" do
    para_string2 = para_string.dup
    100.times do
      para_string2.gsub!(/\w+/) { |m| m+m.size.to_s }
    end
  end
end