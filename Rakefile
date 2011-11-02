PLATFORMS_DIR = '/Developer/Platforms'
SDK_VERSION = '4.3'
PROJECT_VERSION = '0.0.11'

verbose(true)

def rake(dir, cmd='all')
  Dir.chdir(dir) do
    debug = ENV['DEBUG'] ? 'optz_level=0' : ''
    sh "rake platforms_dir=#{PLATFORMS_DIR} sdk_version=#{SDK_VERSION} project_version=#{PROJECT_VERSION} #{debug} #{cmd}"
  end
end

targets = %w{vm lib data doc}

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
  binaries = ['./bin/motion']
  data = []
  data.concat(Dir.glob('./lib/**/*'))
  data.concat(Dir.glob('./data/BridgeSupport/*.bridgesupport'))
  data.concat(%w{./data/deploy ./data/sim ./data/llc ./data/ruby})
  data.concat(Dir.glob('./data/iPhoneOS/*'))
  data.concat(Dir.glob('./data/iPhoneSimulator/*'))
  data.concat(Dir.glob('./doc/html/**/*'))
  data.concat(Dir.glob('./sample/**/*').reject { |path| path =~ /build/ })
  data.reject! { |path| /^\./.match(File.basename(path)) }
  data.reject! { |path| File.directory?(path) }

  files = []
  binaries.each { |x| files << [x, 0755] }
  data.each { |x| files << [x, 0644] }

  destdir = (ENV['DESTDIR'] || '/')
  destdir = File.join(destdir, '/Developer/Motion')
  files.each do |path, mode|
    pathdir = File.join(destdir, File.dirname(path))
    mkdir_p pathdir unless File.exist?(pathdir)
    cp path, File.join(destdir, path)
    chmod mode, File.join(destdir, path)
  end
end
