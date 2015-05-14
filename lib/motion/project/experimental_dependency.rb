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
  class ExperimentalDependency
    begin
      require 'ripper'
    rescue LoadError
      $:.unshift(File.expand_path(File.join(File.dirname(__FILE__), '../../ripper18')))
      require 'ripper'
    end

    @file_paths = []

    def initialize(paths, dependencies)
      @file_paths = paths.flatten.sort
      @dependencies = dependencies
    end

    def cyclic?(dependencies, def_path, ref_path)
      deps = dependencies[def_path]

      if deps
        if deps.include?(ref_path)
          return true
        end
        deps.each do |file|
          return true if cyclic?(dependencies, file, ref_path)
        end
      end

      return false
    end

    def run
      consts_defined  = {}
      consts_referred = {}
      @file_paths.each do |path|
        parser = Constant.new(File.read(path))
        parser.defined.each do |const|
          consts_defined[const] = path
        end
        parser.referred.each do |const|
          consts_referred[const] ||= []
          consts_referred[const] << path
        end
      end

      dependency = @dependencies.dup
      consts_referred.each do |const, ref_paths|
        klasses = const.split('::')
        klass = klasses.pop

        nesting = []
        while !klasses.empty?
          nesting << (klasses + [klass]).join('::')
          klasses.pop
        end
        nesting << klass

        nesting.each do |nesting_ref_path|
          if def_path = consts_defined[nesting_ref_path]
            ref_paths.each do |ref_path|
              next if def_path == ref_path
              next if cyclic?(dependency, def_path, ref_path)
              dependency[ref_path] ||= []
              dependency[ref_path] << def_path
              dependency[ref_path].uniq!
            end
            break
          end
        end
      end

      return dependency
    end

    class Constant
      attr_accessor :defined
      attr_accessor :referred

      def initialize(source)
        @defined = []
        @referred = []

        evaluate_sexp(Ripper.sexp_raw(source))
      end

      def evaluate_sexp(sexp, parents = [])
        # We do not want to modify the original array
        parents = parents.dup

        case sexp[0]
        # Ignore code inside method definitions
        # def foo; end
        # def self.foo; end
        when :def, :defs
          return
        # class A; end
        # module A; end
        when :class, :module
          klass = get_full_const_path(sexp[1])
          register_referred_constants(parents, klass.dup.tap {|a| a.pop})
          parents.concat(klass)
          @defined << parents.join('::')
          if sexp[0] == :class
            superclass = get_full_const_path(sexp[2]).join('::') if sexp[2]
            @referred << superclass if superclass
            evaluate_sexp(sexp[3], parents)
          else
            evaluate_sexp(sexp[2], parents)
          end
        # A, ::A, A::B, ::A::B
        when :const_path_ref, :var_ref, :top_const_ref
          const_path = get_full_const_path(sexp)
          parents = [] if sexp.flatten.include?(:top_const_ref)
          register_referred_constants(parents, const_path)
        # A = 1, ::A = 1, A::B = 1, ::A::B = 1
        when :const_path_field, :var_field, :top_const_field
          const = get_full_const_path(sexp)
          parents = [] if sexp.flatten.include?(:top_const_ref) || sexp.flatten.include?(:top_const_field)
          path = (parents + const).join('::')
          @referred.delete(path)
          register_defined_constants(parents, const)
          const.pop
          register_referred_constants(parents, const)
        else
          # if it is ant other type, continue evaluating
          sexp.count.times do |i|
            evaluate_sexp(sexp[i], parents) if sexp[i].is_a?(Array)
          end
        end
      end

      # Get a full constant path (E.g. A::B::C) from a sexp chain
      def get_full_const_path(sexp, const = [])
        case sexp[0]
        when :var_ref, :top_const_ref, :const_ref
          if sexp[1][0] == :@const
            const << sexp[1][1]
          end
        when :const_path_ref, :const_path_field
          const << sexp[2][1]
          get_full_const_path(sexp[1], const)
        end
        const.reverse
      end

      def register_defined_constants(parents, klasses)
        construct_nest_constants!(@defined, parents, klasses)
      end

      def register_referred_constants(parents, klasses)
        # Do not register a reference if the class itself is contained in the
        # nesting chain. E.g.:
        #
        # class A; class B; class C
        #   B::C
        # end; end; end
        #
        # A::B::C::B::C == A::B::C
        #
        klasses = klasses.dup
        while parents.include?(klasses.first)
          klasses.shift
        end
        return if klasses.empty?

        construct_nest_constants!(@referred, parents, klasses)
      end

      def construct_nest_constants!(consts, parents, klasses)
        chain = klasses.dup
        while !chain.empty?
          path = (parents + chain).join('::')
          consts << path if !consts.include?(path)
          @referred.delete(path) if @defined.include?(path)
          chain.pop
        end
      end
    end
  end
end;end
