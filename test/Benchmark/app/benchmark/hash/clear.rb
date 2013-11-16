def hash_clear(x)
  x.report "clear with empty hash" do
    h = {}
    10000.times do
      h.clear
    end
  end

  x.report "clear" do
    10000.times do
      h = $small_hash.dup
      h.clear
    end
  end
end
