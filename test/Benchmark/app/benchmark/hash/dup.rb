def hash_dup(x)
  x.report "dup" do
    10000.times do
      $small_hash.dup
    end
  end
end
