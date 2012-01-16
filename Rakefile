PLATFORMS_DIR = '/Developer/Platforms'
PROJECT_VERSION = '0.41.pre3'

sim_sdks = Dir.glob(File.join(PLATFORMS_DIR, 'iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator*.sdk')).map do |path|
  File.basename(path).scan(/^iPhoneSimulator(.+)\.sdk$/)[0][0]
end
ios_sdks = Dir.glob(File.join(PLATFORMS_DIR, 'iPhoneOS.platform/Developer/SDKs/iPhoneOS*.sdk')).map do |path|
  File.basename(path).scan(/^iPhoneOS(.+)\.sdk$/)[0][0]
end
SDK_VERSIONS = (sim_sdks & ios_sdks)

if SDK_VERSIONS.empty?
  $stderr.puts "Can't locate any SDK"
  exit 1
end

verbose(true)

def rake(dir, cmd='all')
  Dir.chdir(dir) do
    debug = ENV['DEBUG'] ? 'optz_level=0' : ''
    sh "rake platforms_dir=\"#{PLATFORMS_DIR}\" sdk_versions=\"#{SDK_VERSIONS.join(',')}\" project_version=\"#{PROJECT_VERSION}\" #{debug} #{cmd}"
  end
end

targets = %w{vm bin lib data doc}

task :default => :all
desc "Build everything"
task :all => :build

targets.each do |target|
  desc "Build target #{target}"
  task "build:#{target}" do
    rake(target)
  end
end

desc "Build all targets"
task :build => targets.map { |x| "build:#{x}" }

targets.each do |target|
  desc "Clean target #{target}"
  task "clean:#{target}" do
    rake(target, 'clean')
  end
end

desc "Clean all targets"
task :clean => targets.map { |x| "clean:#{x}" }

desc "Generate source code archive"
task :archive do
  base = "rubymotion-head"
  rm_rf "/tmp/#{base}"
  sh "git archive --format=tar --prefix=#{base}/ HEAD | (cd /tmp && tar xf -)"
  Dir.chdir('vm') do
    sh "git archive --format=tar HEAD | (cd /tmp/#{base}/vm && tar xf -)"
  end
  Dir.chdir('/tmp') do
    sh "tar -czf #{base}.tgz #{base}"
  end
  sh "mv /tmp/#{base}.tgz ."
  sh "du -h #{base}.tgz"
end

desc "Install"
task :install do
  public_binaries = ['./bin/motion']
  binaries = public_binaries.dup.concat(['./bin/deploy', './bin/sim',
    './bin/llc', './bin/ruby'])
  data = ['./NEWS']
  data.concat(Dir.glob('./lib/motion/**/*'))
  SDK_VERSIONS.each do |sdk_version|
    data.concat(Dir.glob("./data/#{sdk_version}/BridgeSupport/*.bridgesupport"))
    data.concat(Dir.glob("./data/#{sdk_version}/iPhoneOS/*"))
    data.concat(Dir.glob("./data/#{sdk_version}/iPhoneSimulator/*"))
  end
  data.concat(Dir.glob('./doc/*.html'))
  data.concat(Dir.glob('./doc/docset/**/*'))
  data.concat(Dir.glob('./sample/**/*').reject { |path| path =~ /build/ })
  data.reject! { |path| /^\./.match(File.basename(path)) }
  data.reject! { |path| File.directory?(path) }

  motiondir = '/Library/Motion'
  destdir = (ENV['DESTDIR'] || '/')
  destmotiondir = File.join(destdir, motiondir)
  install = proc do |path, mode|
    pathdir = File.join(destmotiondir, File.dirname(path))
    mkdir_p pathdir unless File.exist?(pathdir)
    destpath = File.join(destmotiondir, path)
    cp path, destpath
    chmod mode, destpath
    destpath
  end

  binaries.each { |path| install.call(path, 0755) }
  data.each { |path| install.call(path, 0644) }

  bindir = File.join(destdir, '/usr/bin')
  mkdir_p bindir
  public_binaries.each do |path|
    destpath = File.join(motiondir, path)
    ln_sf destpath, File.join(bindir, File.basename(path))
  end
end

desc "Generate .pkg"
task :package do
  ENV['DESTDIR'] = '/tmp/Motion'
  rm_rf '/tmp/Motion'
  Rake::Task[:install].invoke
  sh "/Developer/usr/bin/packagemaker --doc pkg/RubyMotion.pmdoc --out \"pkg/RubyMotion #{PROJECT_VERSION}.pkg\" --version #{PROJECT_VERSION}"
end
