def hash_length(x)
  x.report "length" do
    1000000.times do
      $small_hash.length
    end
  end
end
