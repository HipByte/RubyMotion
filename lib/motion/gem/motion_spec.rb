module Motion; module Gem
  
  # MotionSpec class provides facilites to set up stuff for gem compilation
  class MotionSpec
    attr_accessor :files, :spec_files, :frameworks, :libs, :resources_dir
    
    attr_reader :hooks, :vendor_projects
    
    def initialize
      @files = []
      @spec_files = []
      @frameworks = []
      @libs = []
      @hooks = {}
      @vendor_projects = []
    end
    
    def pre_build(&block)
      @hooks[:pre_build] = block
    end
    
    def vendor_project(*args)
      @vendor_projects << args
    end
  end

end; end
