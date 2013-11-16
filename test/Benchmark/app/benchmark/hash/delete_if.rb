def hash_delete_if(x)
  x.report "delete_if" do
    10000.times do
      small_hash = $small_hash.dup
      small_hash.delete_if { |k,v| v.even? }
    end
  end
end
