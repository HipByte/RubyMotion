PLATFORMS_DIR = '/Applications/Xcode.app/Contents/Developer/Platforms'
PROJECT_VERSION = '0.54'

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
    './bin/llc', './bin/ruby', './bin/ctags'])
  data = ['./NEWS']
  data.concat(Dir.glob('./lib/motion/**/*'))
  SDK_VERSIONS.each do |sdk_version|
    data.concat(Dir.glob("./data/#{sdk_version}/BridgeSupport/*.bridgesupport"))
    data.concat(Dir.glob("./data/#{sdk_version}/iPhoneOS/*"))
    data.concat(Dir.glob("./data/#{sdk_version}/iPhoneSimulator/*"))
  end
  data.concat(Dir.glob('./data/*-ctags.cfg'))
  data.concat(Dir.glob('./doc/*.html'))
  #data.concat(Dir.glob('./doc/docset/**/*'))
  data.concat(Dir.glob('./sample/**/*').reject { |path| path =~ /build/ })
  data.reject! { |path| /^\./.match(File.basename(path)) }

  motiondir = '/Library/Motion'
  destdir = (ENV['DESTDIR'] || '/')
  destmotiondir = File.join(destdir, motiondir)
  install = proc do |path, mode|
    pathdir = File.join(destmotiondir, File.dirname(path))
    mkdir_p pathdir unless File.exist?(pathdir)
    destpath = File.join(destmotiondir, path)
    if File.directory?(path)
      mkdir_p destpath
    else
      cp path, destpath
      chmod mode, destpath
    end
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
  destdir = '/tmp/Motion'
  pkg = "pkg/RubyMotion #{PROJECT_VERSION}.pkg"
  #if !File.exist?(destdir) or !File.exist?(pkg) or File.mtime(destdir) > File.mtime(pkg)
    ENV['DESTDIR'] = destdir
    rm_rf destdir
    Rake::Task[:install].invoke

    sh "/Applications/PackageMaker.app/Contents/MacOS/PackageMaker --doc pkg/RubyMotion.pmdoc --out \"pkg/RubyMotion #{PROJECT_VERSION}.pkg\" --version #{PROJECT_VERSION}"
  #end
end

desc "Push on Amazon S3"
task :upload do
  require 'rubygems'
  require 'aws/s3'

  AWS::S3::Base.establish_connection!(
    :access_key_id => 'AKIAI37ZXXJWNQQ5M45Q',
    :secret_access_key => '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'
  )

  WEBSITE_BUCKET_NAME = 'data.hipbyte.com'

  # Will raise an error if bucket doesn't exist
  AWS::S3::Bucket.find WEBSITE_BUCKET_NAME

  puts "Uploading Latest.."
  AWS::S3::S3Object.store('rubymotion/releases/Latest', PROJECT_VERSION, WEBSITE_BUCKET_NAME)
  puts "Done!"

  file = "pkg/RubyMotion #{PROJECT_VERSION}.pkg"
  puts "Uploading #{file}.."
  AWS::S3::S3Object.store("rubymotion/releases/#{PROJECT_VERSION}.pkg", File.read(file), WEBSITE_BUCKET_NAME)
  puts "Done!"
end
