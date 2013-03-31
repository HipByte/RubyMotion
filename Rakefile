installation_path = "/Library/RubyMotion"

desc "Replace your local installation with this checkout"
task :install do
  if File.exist?("#{installation_path}/lib.backup")
    raise "It seems this local checkout is already installed"
  else
    mv "#{installation_path}/lib", "#{installation_path}/lib.backup"
    ln File.dirname(__FILE__) + "/lib", "#{installation_path}/lib"
  end
end

desc "Go back to your original installation"
task :uninstall do
  if !File.exist?("#{installation_path}/lib.backup")
    raise "It seems this local checkout is not installed right now"
  else
    rm "#{installation_path}/lib"
    mv "#{installation_path}/lib.backup", "#{installation_path}/lib"
  end
end
