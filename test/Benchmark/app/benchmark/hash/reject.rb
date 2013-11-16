def hash_reject(x)
  x.report "reject" do
    10000.times do
      $small_hash.reject { |k,v| v.even?}
    end
  end

  x.report "reject!" do
    10000.times do
      h = $small_hash.dup
      h.reject! { |k,v| v.even?}
    end
  end
end
