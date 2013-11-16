def hash_equal(x)
  x.report "hash == hash" do
    10000.times do
      $small_hash == $small_hash
    end
  end

  x.report "hash == hash.dup" do
    10000.times do
      $small_hash == $small_hash.dup
    end
  end

  x.report "hash == other" do
    10000.times do
      $small_hash == $different_hash
    end
  end
end
