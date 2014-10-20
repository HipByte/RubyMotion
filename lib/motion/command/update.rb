# encoding: utf-8

# Copyright (c) 2012, HipByte SPRL and contributors
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
# 
# 1. Redistributions of source code must retain the above copyright notice, this
#    list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
# ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
# ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

require 'motion/project/builder'
require 'motion/util/version'

module Motion; class Command
  class Update < Command
    self.summary = 'Update the software.'

    def self.options
      [
        ['--check', 'Only check whether or not a newer version is available'],
        ['--pre', 'Install pre-releases of RubyMotion'],
        ['--cache-version=VERSION', 'Install a specific RubyMotion version'],
      ].concat(super)
    end

    def initialize(argv)
      @prerelease_mode = argv.flag?('pre', false)
      @check_mode = argv.flag?('check', false)
      @wanted_software_version = argv.option('cache-version')
      @force_version = argv.option('force-version')
      super
    end

    def validate!
      super
      if @force_version
        help! "--force-version has been deprecated in favor of --cache-version"
      end
      if @wanted_software_version
        die("/Library/RubyMotion.old already exists, please move this directory before using --cache-version") if File.exist?('/Library/RubyMotion.old')
        die "--cache-version can't be used with --pre" if @prerelease_mode
      end
    end

    def run
      if @check_mode
        perform_check
      else
        perform_update
      end
    end

    module Pre
      path = '/Library/RubyMotionPre/lib/motion/version.rb'
      eval(File.read(path)) if File.exist?(path)
    end

    def product_version
      @product_version ||= begin
        if @prerelease_mode and defined?(Pre::Motion::Version)
          Pre::Motion::Version
        else
          Motion::Version
        end
      end
    end

    def curl(cmd)
      resp = `/usr/bin/curl --connect-timeout 60 #{cmd}`
      if $?.exitstatus != 0
        die "Error when connecting to the server. Check your Internet connection and try again."
      end
      resp
    end

    def download(url, dest)
      if system("which axel > /dev/null")
        unless system("axel -n 10 -a -o '#{dest}' '#{url}'")
          die "Error when connecting to the server. Check your Internet connection and try again."
        end
      else
        curl("-# '#{url}' -o '#{dest}'")
      end
    end

    def perform_check
      update_check_file = File.join(ENV['TMPDIR'] || '/tmp', '.motion-update-check')
      if !File.exist?(update_check_file) or (Time.now - File.mtime(update_check_file) > 60 * 60 * 24)
        resp = curl("-s -d \"product=rubymotion\" -d \"current_software_version=#{product_version}\" -d \"license_key=#{read_license_key}\" -d \"pre=#{@prerelease_mode ? 'true' : 'false'}\" https://secure.rubymotion.com/latest_software_version")
        exit 1 unless resp.match(/^\d+\.\d+/)
        File.open(update_check_file, 'w') { |io| io.write(resp) }
      end

      latest_version, message = File.read(update_check_file).split('|', 2)
      message ||= ''
      if Util::Version.new(latest_version) > Util::Version.new(product_version)
        message = "A new version of RubyMotion is available. Run `sudo motion update' to upgrade.\n" + message
      end
      message.strip!
      unless message.empty?
        puts '=' * 80
        puts message
        puts '=' * 80
        puts ''
      end
      exit 1
    end

    def perform_update
      need_root

      $stderr.puts "Connecting to the server..."
      resp = curl("-s -d \"product=rubymotion\" -d \"current_software_version=#{product_version}\" -d \"wanted_software_version=#{@wanted_software_version}\" -d \"license_key=#{read_license_key}\" -d \"pre=#{@prerelease_mode ? 'true' : 'false'}\" https://secure.rubymotion.com/update_software")
      unless resp.match(/^http:/)
        die resp
      end

      $stderr.puts 'Downloading software update...'
      url = resp
      tmp_dest = '/tmp/_rubymotion_su.pkg'
      download(url, tmp_dest)

      if @wanted_software_version or @prerelease_mode
        FileUtils.mv '/Library/RubyMotion', '/Library/RubyMotion.old'
      end

      $stderr.puts "Installing software update..."
      installer = "/usr/sbin/installer -pkg \"#{tmp_dest}\" -target / >& /tmp/installer.stderr"
      unless system(installer)
        die "An error occurred while installing the software update: #{File.read('/tmp/installer.stderr')}"
      end
      FileUtils.rm_f tmp_dest

      if @wanted_software_version
        dest_installation_dir = '/Library/RubyMotion' + @wanted_software_version
        FileUtils.mv '/Library/RubyMotion', dest_installation_dir
        $stderr.puts "RubyMotion #{@wanted_software_version} installed as #{dest_installation_dir}. To use it in a project, edit the Rakefile to point to #{dest_installation_dir}/lib instead of /Library/RubyMotion/lib."
      else
        if @prerelease_mode
          FileUtils.rm_rf '/Library/RubyMotionPre'
          FileUtils.mv '/Library/RubyMotion', '/Library/RubyMotionPre'
          $stderr.puts "RubyMotion pre-release update installed in /Library/RubyMotionPre\n\n"
        else
          $stderr.puts "Software update installed.\n\n"
        end
        news = File.read("/Library/RubyMotion#{@prerelease_mode ? 'Pre' : ''}/NEWS")
        begin
          news.force_encoding('UTF-8')
        rescue
        end

        news.lines.each do |line|
          if md = line.match(/^=\s+RubyMotion\s+(.+)\s+=$/)
            break if md[1] <= product_version
          end
          $stderr.puts line
        end
        $stderr.puts '(Run `motion changelog' + (@prerelease_mode ? ' --pre' : '') + '` to view all changes.)'
      end

      FileUtils.rm_rf Motion::Project::Builder.common_build_dir
    ensure
      if (@wanted_software_version or @prerelease_mode) and File.exist?('/Library/RubyMotion.old')
        FileUtils.mv '/Library/RubyMotion.old', '/Library/RubyMotion'
      end
    end
  end
end; end
