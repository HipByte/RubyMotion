PLATFORMS_DIR = '/Developer/Platforms'
SDK_VERSION = '4.3'
PROJECT_VERSION = '0.14'

verbose(true)

def rake(dir, cmd='all')
  Dir.chdir(dir) do
    debug = ENV['DEBUG'] ? 'optz_level=0' : ''
    sh "rake platforms_dir=#{PLATFORMS_DIR} sdk_version=#{SDK_VERSION} project_version=#{PROJECT_VERSION} #{debug} #{cmd}"
  end
end

targets = %w{vm bin lib data doc}

task :default => :all
desc "Build everything"
task :all => targets

targets.each do |target|
  desc "Build target #{target}"
  task target do
    rake(target)
  end
end

desc "Clean all targets"
task :clean do
  targets.each { |target| rake(target, 'clean') }
  rm_rf 'pkg'
end

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
  data = []
  data.concat(Dir.glob('./lib/motion/**/*'))
  data.concat(Dir.glob('./data/BridgeSupport/*.bridgesupport'))
  data.concat(Dir.glob('./data/iPhoneOS/*'))
  data.concat(Dir.glob('./data/iPhoneSimulator/*'))
  data.concat(Dir.glob('./doc/html/**/*'))
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
