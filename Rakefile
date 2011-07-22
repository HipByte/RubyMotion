PLATFORMS_DIR = '/Developer/Platforms'
SDK_VERSION = '4.3'
PROJECT_VERSION = '0.0.8'

verbose(true)

def rake(dir, cmd='all')
  Dir.chdir(dir) do
    sh "rake platforms_dir=#{PLATFORMS_DIR} sdk_version=#{SDK_VERSION} #{cmd}"
  end
end

targets = %w{vm data doc}

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
  base = "rubixir-head"
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

require 'rubygems'
require 'rake/gempackagetask'
gem_spec = Gem::Specification.new do |spec|
  files = []
  files.concat(Dir.glob('./lib/**/*'))
  files.concat(Dir.glob('./data/BridgeSupport/*.bridgesupport'))
  files.concat(%w{./data/deploy ./data/sim ./data/llc ./data/ruby})
  files.concat(Dir.glob('./data/iPhoneOS/*'))
  files.concat(Dir.glob('./data/iPhoneSimulator/*'))
  files.concat(Dir.glob('./doc/html/**/*'))
  files.concat(Dir.glob('./sample/**/*').reject { |path| path =~ /build/ })
  files.reject! { |path| /^\./.match(File.basename(path)) }
  files.reject! { |path| File.directory?(path) }

  spec.name = 'rubixir'
  spec.summary = 'Ruby runtime for iOS'
  spec.description = <<-DESCRIPTION
Rubixir is an implementation of the Ruby language for the iOS mobile platform.
DESCRIPTION
  #spec.author = 'todo'
  #spec.email = 'todo'
  #spec.homepage = 'todo'
  spec.version = PROJECT_VERSION
  spec.files = files
  #spec.executable = 'rubixir'
end

Rake::GemPackageTask.new(gem_spec) do |pkg|
  pkg.need_zip = false
  pkg.need_tar = true
end
