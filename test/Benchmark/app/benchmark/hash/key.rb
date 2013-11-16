def hash_key(x)
  x.report "key? all match" do
    keys = $small_hash.keys
    10000.times do
      keys.each { |key| $small_hash.key?(key) }
    end
  end

  x.report "key? none match" do
    keys = $small_hash.keys
    10000.times do
      keys.each { |key| $small_hash.key?(nil) }
    end
  end
end
