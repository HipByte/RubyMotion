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

module Motion; module Project; class Command
  class Update < Command
    self.summary = 'Update the software.'
    # TODO make more elaborate
    # self.description = '...'

    def self.options
      [
        ['--check', 'Only check whether or not a newer version is available'],
        ['--cache-version=VERSION', 'Install a specific RubyMotion version'],
      ].concat(super)
    end

    def initialize(argv)
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
      if @wanted_software_version && File.exist?('/Library/RubyMotion.old')
        die("/Library/RubyMotion.old already exists, please move this directory before using --cache-version")
      end
    end

    def run
      if @check_mode
        perform_check
      else
        perform_update
      end
    end

    def product_version
      Motion::Version
    end

    def latest_version?(product, latest)
      product = product.split(".")
      latest  = latest.split(".")
      (product[0].to_i >= latest[0].to_i) && (product[1].to_i >= latest[1].to_i)
    end

    def curl(cmd)
      resp = `/usr/bin/curl --connect-timeout 60 #{cmd}`
      if $?.exitstatus != 0
        die "Error when connecting to the server. Check your Internet connection and try again."
      end
      resp
    end

    def perform_check
      update_check_file = File.join(ENV['TMPDIR'] || '/tmp', '.motion-update-check')
      if !File.exist?(update_check_file) or (Time.now - File.mtime(update_check_file) > 60 * 60 * 24)
        resp = curl("-s -d \"product=rubymotion\" -d \"current_software_version=#{product_version}\" -d \"license_key=#{read_license_key}\" https://secure.rubymotion.com/latest_software_version")
        exit 1 unless resp.match(/^\d+\.\d+/)
        File.open(update_check_file, 'w') { |io| io.write(resp) }
      end

      latest_version, message = File.read(update_check_file).split('|', 2)
      message ||= ''
      unless latest_version?(product_version, latest_version)
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
      resp = curl("-s -d \"product=rubymotion\" -d \"current_software_version=#{product_version}\" -d \"@wanted_software_version=#{@wanted_software_version}\" -d \"license_key=#{read_license_key}\" https://secure.rubymotion.com/update_software")
      unless resp.match(/^http:/)
        die resp
      end

      $stderr.puts 'Downloading software update...'
      url = resp
      tmp_dest = '/tmp/_rubymotion_su.pkg'
      curl("-# \"#{url}\" -o #{tmp_dest}")

      if @wanted_software_version
        $stderr.puts 'Saving current RubyMotion version...'
        FileUtils.mv '/Library/RubyMotion', '/Library/RubyMotion.old'
      end

      $stderr.puts "Installing software update..."
      installer = "/usr/sbin/installer -pkg \"#{tmp_dest}\" -target / >& /tmp/installer.stderr"
      unless system(installer)
        die "An error occurred while installing the software update: #{File.read('/tmp/installer.stderr')}"
      end
      FileUtils.rm_f tmp_dest

      if @wanted_software_version
        FileUtils.mv '/Library/RubyMotion', "/Library/RubyMotion#{@wanted_software_version}"
        $stderr.puts 'Restoring current RubyMotion version...' # done in ensure
        $stderr.puts "RubyMotion #{@wanted_software_version} installed as /Library/RubyMotion#{@wanted_software_version}. To use it in a project, edit the Rakefile to point to /Library/RubyMotion#{@wanted_software_version}/lib instead of /Library/RubyMotion/lib."
      else
        $stderr.puts "Software update installed.\n\n"
        news = File.read('/Library/RubyMotion/NEWS')
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
        $stderr.puts '(Run `motion changelog` to view all changes.)'
      end

      FileUtils.rm_rf Motion::Project::Builder.common_build_dir
    ensure
      if @wanted_software_version && File.exist?('/Library/RubyMotion.old')
        FileUtils.mv '/Library/RubyMotion.old', '/Library/RubyMotion'
      end
    end
  end
end; end; end
