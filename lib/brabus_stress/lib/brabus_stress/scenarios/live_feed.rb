module BrabusStress
  module Scenarios
    class LiveFeed
      
      def self.run!
        @runner = BrabusStress::BenchmarkProxy.new(BrabusStress::Runner.new)
        
        @runner.connect!
        @runner.balance
        @runner.signup_and_login
        @runner.sync_delta
        @runner.location
      end
      
    end      
  end
end