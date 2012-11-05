require 'benchmark'

module BrabusStress
  class BenchmarkProxy
    instance_methods.each do |m|
      undef_method(m) unless (m.match(/^__/) or m.match(/object_id/))
    end
    
    
    def initialize(object)
      @object = object
    end
    
    def method_missing(sym, *args, &block)
      @object.logger.info "#{Time.now.utc.to_s} | #{sym.to_s} | \t #{Benchmark.measure {@object.__send__(sym, *args, &block)}}"
    end
    
  end
end