def hash_delete(x)
  small_hash = $small_hash.dup
  x.report "delete" do
    1000000.times do
      small_hash.delete(:jaWa)
    end
  end
end
