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

module Motion; module Project;
  class ParallelBuilder
    attr_accessor :files

    def initialize(objs_build_dir, builder)
      @builders_count = begin
        if jobs = ENV['jobs']
          jobs.to_i
        else
          `/usr/sbin/sysctl -n machdep.cpu.thread_count`.strip.to_i
        end
      end
      @builders_count = 1 if @builders_count < 1

      @builders = []
      @builders_count.times do
        queue = []
        th = Thread.new do
          sleep
          objs = []
          while arg = queue.shift
            objs << builder.call(objs_build_dir, arg[0], arg[1])
          end
          queue.concat(objs)
        end
        @builders << [queue, th]
      end
    end

    def run
      builder_i = 0
      @files.each do |path|
        @builders[builder_i][0] << [path, builder_i]
        builder_i += 1
        builder_i = 0 if builder_i == @builders_count
      end

      # Start build.
      @builders.each do |queue, th|
        sleep 0.01 while th.status != 'sleep'
        th.wakeup
      end
      @builders.each { |queue, th| th.join }
      @builders
    end

    def objects
      objs = []
      builder_i = 0
      @files.each do |path|
        objs << @builders[builder_i][0].shift
        builder_i += 1
        builder_i = 0 if builder_i == @builders_count
      end
      objs
    end
  end
end;end