def hash_each(x)
  x.report "each" do
    100000.times do
      $small_hash.each do |k, v|
      end
    end
  end
end
