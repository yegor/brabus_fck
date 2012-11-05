module BrabusStress
  module Scenarios
    class LiveFeed
      
      def self.run!
        @runner = BrabusStress::BenchmarkProxy.new(BrabusStress::Runner.new)
        
        @runner.connect!
        @runner.balance
        @runner.signup_and_login
        @runner.sync_delta
        100.times do |i| 
          @runner.location
          @runner.post_to_live_feed(i)
        end
      end
      
    end      
  end
end