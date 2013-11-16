def array_reject(x)
  large_array = $large_array.dup
  x.report "reject all" do |times|
    1000.times do
      large_array.reject { |v| true }
    end
  end

  x.report "reject none" do |times|
    1000.times do
      large_array.reject { |v| false }
    end
  end

  x.report "reject! all" do |times|
    1000.times do
      large_array = $large_array.dup
      large_array.reject! { |v| true }
    end
  end

  x.report "reject! none" do |times|
    1000.times do
      large_array.reject! { |v| false }
    end
  end
end