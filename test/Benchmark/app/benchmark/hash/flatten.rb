def hash_flatten(x)
  x.report "flatten" do
    10000.times do
      $small_hash.flatten
    end
  end
end
