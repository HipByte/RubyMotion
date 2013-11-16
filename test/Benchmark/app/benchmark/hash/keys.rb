def hash_keys(x)
  x.report "keys" do
    100000.times do
      $small_hash.keys
    end
  end
end
