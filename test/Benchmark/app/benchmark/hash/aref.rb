def hash_aset(x)
  x.report "hash[key]= with exist key" do
    h = $small_hash.dup
    1000000.times do |i|
      h[:SlBkyplxcZ] = i
    end
  end

  x.report "hash[key]= with new hash" do
    h = {}
    1000000.times do |i|
      h[i] = i
    end
  end

end
