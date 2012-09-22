module Kernel
  unless(defined? require_relative)
    def require_relative(path)
      require File.join(File.dirname(caller(0)[1]), path.to_str)
    end
  end
end

Exception.log_exceptions = false
