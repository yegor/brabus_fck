require 'benchmark'

module BrabusStress
  class BenchmarkProxy
    # Blank slate
    instance_methods.each do |m|
      undef_method(m) unless (m.match(/^__/) or m.match(/object_id/))
    end
    
    
    def initialize(object, scenario)
      @object = object
      p "#{Time.now.utc.strftime "%H:%M:%S:%L"} | starting #{scenario.to_s}..."
    end
    
    def method_missing(sym, *args, &block)
      time = Time.now.utc
      @object.logger.info "action | #{args.first} | #{Time.now.utc.strftime "%H:%M:%S:%L"} | \t #{Benchmark.measure {@object.__send__(sym, *args, &block)}}"
    end
    
  end
end