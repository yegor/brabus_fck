module BrabusStress
  module Sync
    def sync(object, finalizer)
      runner_proxy = BrabusStress::RunnerProxy.new(object, finalizer)
      
      yield runner_proxy
      
      runner_proxy.start
    end
  end
  
  class RunnerProxy
    attr_accessor :actions, :object, :finalizer
    
    def initialize(object, finalizer)
      @object = object
      @actions = []
      @finalizer = finalizer
    end
    
    def start
      perform_action @actions, nil
    end
    
    protected
    
      def perform_action(actions, argument)
        if actions.empty?
          @object.logger.flush
          @finalizer.try(:call)
          return
        end
        
        action = actions.shift
        
        args = (action[:args] || [])
        args << argument unless argument.blank?
        
        begin
          @object.send action[:action], *args do |result|
            perform_action(actions, result)
          end
        rescue => e
          @object.logger.info "#{e.message}"
        ensure
          @object.logger.flush
        end
      end
      
      def method_missing(method, *args, &block)
        @actions << {:action => method, :args => args}
      end
      
  end
end