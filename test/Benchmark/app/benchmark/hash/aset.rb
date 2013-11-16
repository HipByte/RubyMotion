def hash_aref(x)
  x.report "hash[key] with exist key" do
    1000000.times do
      $small_hash[:SlBkyplxcZ]
    end
  end

  x.report "hash[key] with unknown key" do
    1000000.times do
      $small_hash[:SlBkdfadsfs]
    end
  end

end
