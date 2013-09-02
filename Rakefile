PROJECT_VERSION = '2.8'
PLATFORMS_DIR = (ENV['PLATFORMS_DIR'] || '/Applications/Xcode.app/Contents/Developer/Platforms')

sim_sdks = Dir.glob(File.join(PLATFORMS_DIR, 'iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator*.sdk')).map do |path|
  File.basename(path).scan(/^iPhoneSimulator(.+)\.sdk$/)[0][0]
end
ios_sdks = Dir.glob(File.join(PLATFORMS_DIR, 'iPhoneOS.platform/Developer/SDKs/iPhoneOS*.sdk')).map do |path|
  File.basename(path).scan(/^iPhoneOS(.+)\.sdk$/)[0][0]
end
IOS_SDK_VERSIONS = (sim_sdks & ios_sdks)

if IOS_SDK_VERSIONS.empty?
  $stderr.puts "Can't locate any iOS SDK"
  exit 1
end

OSX_SDK_VERSIONS = Dir.glob(File.join(PLATFORMS_DIR, 'MacOSX.platform/Developer/SDKs/MacOSX*.sdk')).map do |path|
  File.basename(path).scan(/^MacOSX(.+)\.sdk$/)[0][0]
end

if OSX_SDK_VERSIONS.empty?
  $stderr.puts "Can't locate any OSX SDK"
  exit 1
end

if false
  # DEBUG
  IOS_SDK_VERSIONS.clear; IOS_SDK_VERSIONS << '6.1'
  OSX_SDK_VERSIONS.clear; OSX_SDK_VERSIONS << '10.8'
end

verbose(true)

def rake(dir, cmd='all')
  Dir.chdir(dir) do
    debug = ENV['DEBUG'] ? 'optz_level=0' : ''
    sdk_beta = ENV['SDK_BETA'] ? 'sdk_beta=1' : ''
    trace = Rake.application.options.trace
    sh "rake platforms_dir=\"#{PLATFORMS_DIR}\" ios_sdk_versions=\"#{IOS_SDK_VERSIONS.join(',')}\" osx_sdk_versions=\"#{OSX_SDK_VERSIONS.join(',')}\" project_version=\"#{PROJECT_VERSION}\" #{debug} #{sdk_beta} #{cmd} #{trace ? '--trace' : ''}"
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
  binaries = public_binaries.dup.concat(['./bin/ios/deploy', './bin/ios/sim',
    './bin/osx/sim', './bin/llc', './bin/ruby', './bin/ctags', './bin/nfd',
    'lib/yard/bin/yard', 'lib/yard/bin/yardoc', 'lib/yard/bin/yri', './lldb/lldb.py'])
  data = ['./NEWS']
  data.concat(Dir.glob('./lib/**/*', File::FNM_DOTMATCH) - ['./lib/Rakefile'])
  data.delete_if { |x| true if x.include?("lib/yard/bin/") }
  [['ios', IOS_SDK_VERSIONS + ['7.0']]].each do |name, sdk_versions|
    sdk_versions.each do |sdk_version|
      data.concat(Dir.glob("./data/#{name}/#{sdk_version}/BridgeSupport/*.bridgesupport"))
      data.concat(Dir.glob("./data/#{name}/#{sdk_version}/iPhoneSimulator/*"))
      data.concat(Dir.glob("./data/#{name}/#{sdk_version}/iPhoneOS/*"))
    end
  end
  [['osx', OSX_SDK_VERSIONS + ['10.9']]].each do |name, sdk_versions|
    sdk_versions.each do |sdk_version|
      data.concat(Dir.glob("./data/#{name}/#{sdk_version}/BridgeSupport/*.bridgesupport"))
      data.concat(Dir.glob("./data/#{name}/#{sdk_version}/MacOSX/*"))
    end
  end

  # Android support is not ready yet.
  data.delete_if { |x| x.match(/^.\/lib\/motion\/project\/template\/android/) }

=begin
  # === 6.0 support (beta) ===
  data.concat(Dir.glob("./data/6.0/Rakefile"))
  data.concat(Dir.glob("./data/6.0/BridgeSupport/RubyMotion.bridgesupport"))
  data.concat(Dir.glob("./data/6.0/BridgeSupport/UIAutomation.bridgesupport"))
  data.concat(Dir.glob("./data/6.0/iPhoneOS/*"))
  data.concat(Dir.glob("./data/6.0/iPhoneSimulator/*"))
  # ==========================
=end

  data.concat(Dir.glob('./data/*-ctags.cfg'))
  #data.concat(Dir.glob('./doc/*.html'))
  #data.concat(Dir.glob('./doc/docset/**/*'))
  #data.concat(Dir.glob('./sample/**/*').reject { |path| path =~ /build/ })
  data.reject! { |path|
    case File.basename(path)
    when ".", "..", ".DS_Store", /\..*swp/
      true
    else
      false
    end
  }

  motiondir = '/Library/RubyMotion'
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

  if File.exists?("vm/.yardoc")
    docdir = File.join(destmotiondir, '/doc')
    mkdir_p docdir
    cp_r "vm/.yardoc", docdir
    rm_rf "#{docdir}/yardoc"
    mv "#{docdir}/.yardoc", "#{docdir}/yardoc"
  end

=begin
  # Gems (only for beta).
  gemsdir = File.join(destmotiondir, 'gems')
  mkdir_p gemsdir
  cp '../motion-testflight/pkg/motion-testflight-1.0.gem', gemsdir
=end
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
  require 'yaml'

  s3config = YAML.load(File.read('s3config.yaml'))

  AWS::S3::Base.establish_connection!(
    :access_key_id => s3config[:access_key_id],
    :secret_access_key => s3config[:secret_access_key]
  )

  WEBSITE_BUCKET_NAME = 'data.hipbyte.com'

  # Will raise an error if bucket doesn't exist
  AWS::S3::Bucket.find WEBSITE_BUCKET_NAME

  file = "pkg/RubyMotion #{PROJECT_VERSION}.pkg"
  puts "Uploading #{file}.."
  AWS::S3::S3Object.store("rubymotion/releases/#{PROJECT_VERSION}.pkg", File.read(file), WEBSITE_BUCKET_NAME)
  puts "Done!"

  puts "Uploading Latest.."
  AWS::S3::S3Object.store('rubymotion/releases/Latest', PROJECT_VERSION, WEBSITE_BUCKET_NAME)
  puts "Done!"
end

namespace :doc do
  require './doc/docset'
  require './doc/docset_link'
  require './doc/docset_generator'
  require 'fileutils'

  YARDOC = "cd vm; bundle1.9.3 exec yardoc --legacy"
  RUBY_SOURCES = %w{
    array.c bignum.c class.c compar.c complex.c dir.c encoding.c enum.c
    enumerator.c env.c error.c eval.c eval_error.c eval_jump.c eval_safe.c
    file.c hash.c io.c kernel.c load.c marshal.c math.c numeric.c object.c
    pack.c prec.c proc.c process.c random.c range.c rational.c re.c
    signal.c sprintf.c string.c struct.c symbol.c thread.c time.c
    transcode.c ucnv.c util.c variable.c vm.cpp vm_eval.c vm_method.c
    NSArray.m NSDictionary.m NSString.m bridgesupport.cpp gcd.c objc.m sandbox.c
  }
  DOCSET_PATH = '~/Library/Developer/Shared/Documentation/DocSets/com.apple.adc.documentation.AppleiOS6.0.iOSLibrary.docset/Contents/Resources/Documents/documentation'
  DOCSET = [
    DOCSET_PATH + '/AVFoundation/Reference',
    DOCSET_PATH + '/Cocoa/Reference', # xxx we may need to filter here
    DOCSET_PATH + '/CoreData/Reference',
    DOCSET_PATH + '/CoreFoundation/Reference',
    DOCSET_PATH + '/CoreImage/Reference',
    DOCSET_PATH + '/CoreLocation/Reference',
    DOCSET_PATH + '/CoreMotion/Reference',
    DOCSET_PATH + '/DataManagement/Reference',
    DOCSET_PATH + '/EventKit/Reference',
    DOCSET_PATH + '/EventKitUI/Reference',
    DOCSET_PATH + '/Foundation/Reference',
    DOCSET_PATH + '/GameKit/Reference',
    DOCSET_PATH + '/GraphicsImaging/Reference',
    DOCSET_PATH + '/iAd/Reference',
    DOCSET_PATH + '/MapKit/Reference',
    DOCSET_PATH + '/MediaPlayer/Reference',
    DOCSET_PATH + '/MessageUI/Reference',
    DOCSET_PATH + '/NetworkingInternet/Reference',
    DOCSET_PATH + '/PassKit/Reference',
    DOCSET_PATH + '/QuartzCore/Reference',
    DOCSET_PATH + '/Social/Reference',
    DOCSET_PATH + '/StoreKit/Reference',
    DOCSET_PATH + '/UIKit/Reference',
    DOCSET_PATH + '/UserExperience/Reference'
  ] 
  OUTPUT_DIR = "api"
  DOCSET_RUBY_FILES_DIR = '/tmp/rb_docset'

  desc "Generate API Documents"
  task :api do
    FileUtils.mkdir_p(OUTPUT_DIR)

    # generate Ruby code from iOS SDK docset
    DocsetGenerator.new('docset', DOCSET).generate_ruby_code

    # generate .md files for frameworks
    frameworks_hash = {}
    all_protocols = []
    all_enumerations = []
    ruby_files = Dir.glob(File.join(DOCSET_RUBY_FILES_DIR, '*.rb'))
    ruby_files.each do |x|
      data = File.read(x)
      # determine framework name
      framework = nil
      if md = data.match(/#\s+\-\*\-\s+framework:\s+([^\s]+)\s+\-\*\-/)
        path = md[1]
        base = File.basename(path)
        case File.extname(base)
          when '.framework'
            framework = base.sub(/\.framework/, '')
          when '.h'
            components = path.split(/\//)
            framework = components[-2]
            framework = components[-3] if framework == 'Headers'
          else
            framework = base unless base.include?('/')
        end
      end
      next unless framework
      # get the list of classes
      classes = data.scan(/^class\s+([^\s\n]+)/).flatten
      # get the list of protocols
      protocols = data.scan(/^module\s+([^\s\n]+) # Protocol/).flatten
      # get the list of enumerations
      enumerations = data.scan(/^module\s+([^\s\n]+) # Enumeration/).flatten
      # get the list of functions
      functions = data.scan(/^def\s+([^\s\n\(]+)/).flatten
      if !classes.empty? or !protocols.empty? or !functions.empty? or !enumerations.empty?
        ary = (frameworks_hash[framework] ||= [[], [], [], []])
        ary[0].concat(classes)
        ary[1].concat(protocols)
        ary[2].concat(functions)
        ary[3].concat(enumerations)
      end
      all_protocols.concat(protocols)
      all_enumerations.concat(enumerations)
    end
    frameworks_hash.each do |name, ary|
      classes, protocols, functions, enumerations = ary
      next if name == 'AppKit'
      File.open("#{OUTPUT_DIR}/#{name}.md", 'w') do |io|
        io.puts "# @markup markdown"
        io.puts "# @title #{name}"
        io.puts "# #{name} Reference"
        unless classes.empty?
          io.puts "\n## Classes"
          classes.sort.each do |klass|
            io.puts "- [#{klass}](#{klass}.html)"
          end
        end
        unless protocols.empty?
          io.puts "\n## Protocols"
          protocols.sort.each do |prot|
            io.puts "- [#{prot}](#{prot}.html)"
          end
        end
        unless functions.empty?
          io.puts "\n## Functions"
          functions.sort.each do |func|
            io.puts "- [#{func}](top-level-namespace.html##{func}%3A-instance_method)"
          end
        end
        unless enumerations.empty?
          io.puts "\n## Enumerations"
          enumerations.sort.each do |enum|
            io.puts "- [#{enum}](#{enum}.html)"
          end
        end
      end
    end

    # generate yard documentation
    rubymotion_files = RUBY_SOURCES.join(" ")
    docset_files = ruby_files.join(" ")
    frameworks = Dir.glob(File.join(OUTPUT_DIR, '*.md')).map{ |x| "../#{x}" }.join(" ")

    sh "#{YARDOC} --title 'RubyMotion API Reference' -o ../#{OUTPUT_DIR} #{rubymotion_files} #{docset_files} - ../doc/RubyMotion.md #{frameworks}"
    FileUtils.ln "#{OUTPUT_DIR}/_index.html", "#{OUTPUT_DIR}/index.html" unless File.exist?("#{OUTPUT_DIR}/index.html")

    # update Enumeration/Protocol documents
    [[all_protocols, 'Protocol'], [all_enumerations, 'Enumeration']].each do |ary, new_title|
      ary.each do |name|
        DocsetGenerator.modify_document_title("#{OUTPUT_DIR}/#{name.strip}.html", new_title)
      end
    end

    # generate link
    print "\n\n"
    puts "Now update object link... please wait"
    linker = DocsetGenerator::Linker.new(OUTPUT_DIR)
    Dir.glob(File.join(OUTPUT_DIR, "*.html")).each do |file|
      linker.run(file)
    end
  end

  desc "Generate RubyMotion.docset file"
  task :docset do
    PATH_DOCSET = "RubyMotion.docset"
    INFO_PLIST =<<'END'
<?xml version="1.0" encoding="UTF-8"?>
<plist version="1.0">
<dict>
<key>CFBundleIdentifier</key>
<string>rubymotion</string>
<key>CFBundleName</key>
<string>RubyMotion</string>
<key>DocSetPlatformFamily</key>
<string>rubymotion</string>
<key>isDashDocset</key>
<true/></dict>
</plist>
END

    PATH_CONTENTS  = File.join(PATH_DOCSET, "Contents")
    PATH_RESOURCES = File.join(PATH_CONTENTS, "Resources")
    PATH_DOCUMENTS = File.join(PATH_RESOURCES, "Documents")
    PATH_DOCS      = File.join(PATH_DOCUMENTS, OUTPUT_DIR)

    mkdir_p PATH_DOCUMENTS
    cp_r OUTPUT_DIR, PATH_DOCUMENTS

    File.open(File.join(PATH_CONTENTS, "info.plist"), "w") { |io| io.print INFO_PLIST }

    docset = DocsetGenerator::Generator.new
    Dir.glob(File.join(PATH_DOCS, "/**/*.html")) do |path|
      path.sub!("#{PATH_DOCUMENTS}/", '')
      next if path =~ /index.html/
      next if path =~ /class_list.html/
      next if path =~ /frames.html/
      next if path =~ /file_list.html/
      next if path =~ /file\.\w+\.html/
      next if path =~ /method_list.html/
      docset.parse(PATH_DOCUMENTS, path)
    end

    docset.index(PATH_RESOURCES)
  end

  namespace :list do
    def save_class_list(title, doc_output_dir, output_file_path)
      doc_files = Dir.glob(File.join(doc_output_dir, '**/*.html')).sort.map { |x| x.sub("#{doc_output_dir}/", '')}
      File.open(output_file_path, "w") { |io|
        io.puts "# @markup markdown"
        io.puts "# @title #{title}"
        io.puts "# #{title}"

        doc_files.each do |file|
          next if file =~ /index.html/
          next if file =~ /_list.html/
          next if file == "frames.html"
          next if file == "top-level-namespace.html"

          class_name = file.sub(/(\w+)\/(\w+)/, '\1::\2')
          class_name = class_name.sub('.html', '')
          io.puts "- [#{class_name}](#{file})"
        end
      }
    end

    desc "Generate RubyMotion Classes List"
    task :rubymotion do
      OUTPUT_RUBY_DOC_DIR = '/tmp/rubymotion_doc'

      rubymotion_files = RUBY_SOURCES.join(" ")

      FileUtils.rm_rf OUTPUT_RUBY_DOC_DIR
      sh "#{YARDOC} -o #{OUTPUT_RUBY_DOC_DIR} #{rubymotion_files}"
      save_class_list("RubyMotion", OUTPUT_RUBY_DOC_DIR, "doc/RubyMotion.md")
    end
  end
end
