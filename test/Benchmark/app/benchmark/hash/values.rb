def hash_values(x)
  x.report "values" do
    100000.times do
      $small_hash.values
    end
  end
end
