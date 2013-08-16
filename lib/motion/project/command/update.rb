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

module Motion; module Project
  class UpdateCommand < Command
    self.name = 'update'
    self.help = 'Update the software'

    def curl(cmd)
      resp = `/usr/bin/curl --connect-timeout 60 #{cmd}`
      if $?.exitstatus != 0
        die "Error when connecting to the server. Check your Internet connection and try again."
      end
      resp
    end

    def run(args)
      check_mode = false
      wanted_software_version = nil
      args.each do |a|
        case a
          when '--check'
            check_mode = true
          when /--cache-version=(.+)/
            die("/Library/RubyMotion.old already exists, please move this directory before using --cache-version") if File.exist?('/Library/RubyMotion.old')
            wanted_software_version = $1.to_s
          when /--force-version=(.+)/
            die "–-force-version has been removed in favor of –-cache-version"
          else
            die "Usage: motion update [--cache-version=X]"
        end
      end

      license_key = read_license_key
      product_version = Motion::Version

      if check_mode
        update_check_file = File.join(ENV['TMPDIR'] || '/tmp', '.motion-update-check')
        if !File.exist?(update_check_file) or (Time.now - File.mtime(update_check_file) > 60 * 60 * 24)
          resp = curl("-s -d \"product=rubymotion\" -d \"current_software_version=#{product_version}\" -d \"license_key=#{license_key}\" https://secure.rubymotion.com/latest_software_version")
          exit 1 unless resp.match(/^\d+\.\d+/)
          File.open(update_check_file, 'w') { |io| io.write(resp) }
        end

        latest_version, message = File.read(update_check_file).split('|', 2)
        message ||= ''
        if latest_version > product_version
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

      need_root

      $stderr.puts "Connecting to the server..."
      resp = curl("-s -d \"product=rubymotion\" -d \"current_software_version=#{product_version}\" -d \"wanted_software_version=#{wanted_software_version}\" -d \"license_key=#{license_key}\" https://secure.rubymotion.com/update_software")
      unless resp.match(/^http:/)
        die resp
      end

      $stderr.puts 'Downloading software update...'
      url = resp
      tmp_dest = '/tmp/_rubymotion_su.pkg'
      curl("-# \"#{url}\" -o #{tmp_dest}")

      if wanted_software_version
        $stderr.puts 'Saving current RubyMotion version...'
        FileUtils.mv '/Library/RubyMotion', '/Library/RubyMotion.old'
      end

      $stderr.puts "Installing software update..."
      installer = "/usr/sbin/installer -pkg \"#{tmp_dest}\" -target / >& /tmp/installer.stderr"
      unless system(installer)
        die "An error happened when installing the software update: #{File.read('/tmp/installer.stderr')}"
      end
      FileUtils.rm_f tmp_dest

      if wanted_software_version
        FileUtils.mv '/Library/RubyMotion', "/Library/RubyMotion#{wanted_software_version}"
        $stderr.puts 'Restoring current RubyMotion version...' # done in ensure
        $stderr.puts "RubyMotion #{wanted_software_version} installed as /Library/RubyMotion#{wanted_software_version}, change the Rakefile to /Library/RubyMotion#{wanted_software_version}/lib to use it. Keep /Library/RubyMotion/lib to live on the edge."
      else
        $stderr.puts "Software update installed.\n\n"
        news = File.read('/Library/RubyMotion/NEWS')
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
      if wanted_software_version && File.exist?('/Library/RubyMotion.old')
        FileUtils.mv '/Library/RubyMotion.old', '/Library/RubyMotion'
      end
    end
  end
end; end
