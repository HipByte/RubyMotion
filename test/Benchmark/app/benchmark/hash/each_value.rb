def hash_each_value(x)
  x.report "each_value" do
    100000.times do
      $small_hash.each_value do |kv|
      end
    end
  end
end
