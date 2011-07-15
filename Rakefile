PLATFORMS_DIR = '/Developer/Platforms'
SDK_VERSION = '4.3'

def rake(dir, cmd='all')
  Dir.chdir(dir) do
    sh "rake platforms_dir=#{PLATFORMS_DIR} sdk_version=#{SDK_VERSION} #{cmd}"
  end
end

targets = %w{vm data doc}

task :default => :all
task :all => targets

targets.each do |target|
  task target do
    rake(target)
  end
end

task :clean do
  targets.each { |target| rake(target, 'clean') }
end
