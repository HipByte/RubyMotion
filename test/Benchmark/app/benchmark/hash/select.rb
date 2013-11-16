def hash_select(x)
  x.report "select all" do
    10000.times do
      $small_hash.select { |k,v| true }
    end
  end

  x.report "select none" do
    10000.times do
      $small_hash.select { |k,v| false }
    end
  end  
end
