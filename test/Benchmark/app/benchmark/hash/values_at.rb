def hash_values_at(x)
  x.report "values_at" do
    1000000.times do
      $small_hash.values_at(700648627, 639030613, 471761289)
    end
  end
end
