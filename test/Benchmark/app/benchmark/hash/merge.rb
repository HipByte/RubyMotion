def hash_merge(x)
  hash = $small_hash.dup
  x.report "merge" do
    10000.times do
      hash.merge($different_hash)
    end
  end

  x.report "merge with block" do
    10000.times do
      hash.merge($different_hash) {|k,o,n| n }
    end
  end

  x.report "merge!" do
    10000.times do
      h = $small_hash.dup
      h.merge($different_hash)
    end
  end

  x.report "merge! with block" do
    10000.times do
      h = $small_hash.dup
      h.merge($different_hash) {|k,o,n| n }
    end
  end

end
