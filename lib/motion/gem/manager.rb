require 'singleton'

module Motion; module Gem
  
  class Manager
    include Singleton
    
    attr_reader :specs
    
    def initialize
      @specs = {}
    end
  end
  
end; end
