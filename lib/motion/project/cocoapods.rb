# Copyright (c) 2012, Laurent Sansonetti <lrz@hipbyte.com>
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
# 
# 1. Redistributions of source code must retain the above copyright notice,
#    this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.

unless defined?(Motion::Project::Config)
  raise "This file must be required within a RubyMotion project Rakefile."
end

require 'cocoapods'

class CocoaPodsConfig
  def initialize(config)
    @config = config
    @podfile = Pod::Podfile.new {}
    @podfile.platform :ios

    Pod::Config.instance.silent = true
    Pod::Config.instance.instance_variable_set(:@project_pods_root, Pathname.new(File.join(config.project_dir, 'vendor')))
  end

  def dependency(*name_and_version_requirements, &block)
    @podfile.dependency(*name_and_version_requirements, &block)
  end

  def resolve!
    installer = Pod::Installer.new(@podfile)
    installer.install_dependencies!
    specs = installer.build_specifications
    header_paths = specs.map do |podspec|
      podspec.expanded_source_files.select do |p|
        File.extname(p) == '.h'
      end.map do |p|
        "-I\"" + File.expand_path(File.join('./vendor', File.dirname(p))) + "\""
      end
    end.flatten.join(' ')
    specs.each do |podspec|
     cflags = (podspec.compiler_flags or '') + ' ' + header_paths
      source_files = podspec.expanded_source_files.map do |path|
        # Remove the first part of the path which is the project directory.
        path.to_s.split('/')[1..-1].join('/')
      end
   
      @config.vendor_project(podspec.pod_destroot, :static,
        :cflags => cflags,
        :source_files => source_files)

      ldflags = podspec.xcconfig.to_hash['OTHER_LDFLAGS']
      if ldflags
        @config.frameworks += (ldflags.scan(/-framework\s+([^\s]+)/)[0] or [])
        @config.libs += (ldflags.scan(/-l([^\s]+)/)[0] or []).map { |n| "/usr/lib/lib#{n}.dylib" }
      end

=begin
      # Remove .h files that are not covered in the podspec, to avoid
      # future preprocessor #include collisions.
      headers_to_ignore = (Dir.chdir(podspec.pod_destroot) do
        Dir.glob('*/**/*.h')
      end) - source_files.select { |p| File.extname(p) == '.h' }
p headers_to_ignore,source_files.select { |p| File.extname(p) == '.h' } ,:ok
      #headers_to_ignore.each { |p| FileUtils.rm_rf File.join(podspec.pod_destroot, p) }
=end
    end
  end
end

module Motion; module Project; class Config
  variable :pods

  def pods(&block)
    @pods ||= CocoaPodsConfig.new(self)
    if block
      @pods.instance_eval(&block)
      @pods.resolve!
    end
    @pods
  end
end; end; end
