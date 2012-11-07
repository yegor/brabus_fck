module BrabusStress
  module Scenarios
    class LiveFeed
      
      def self.run!
        @runner = BrabusStress::BenchmarkProxy.new(BrabusStress::Runner.new, self)
        
        @runner.connect!
        @runner.balance
        @runner.signup_and_login
        @runner.sync_delta
        
        BrabusStress::LOOP_COUNT.times do |i| 
          @runner.post_to_live_feed(i)
        end
        
        @runner.logout
      end

    end
  end
end