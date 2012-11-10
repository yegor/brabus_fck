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
      
      @object.__send__(sym, *args) do |result|
        # we get here upon execution finalization
        bm = Time.now.utc.to_f - time.to_f
        @object.logger.info "action | #{args.first} | #{Time.now.utc.strftime "%H:%M:%S:%L"} | \t %3.6f" % bm
        yield result
      end
    end
    
  end
end