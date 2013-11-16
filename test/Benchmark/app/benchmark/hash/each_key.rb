def hash_each_key(x)
  x.report "each_key" do
    100000.times do
      $small_hash.each_key do |k|
      end
    end
  end
end
