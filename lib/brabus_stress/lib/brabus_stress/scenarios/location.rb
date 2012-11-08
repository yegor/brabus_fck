module BrabusStress
  module Scenarios
    class Location
      extend BrabusStress::Sync
      
      def self.run!(memo = nil, &block)
        sync(BrabusStress::BenchmarkProxy.new(BrabusStress::Runner.new, self), block) do |runner|
          runner.connect
          runner.signup_and_login
          runner.sync_delta
          BrabusStress::LOOP_COUNT.times {runner.location}
          runner.logout
          runner.disconnect
        end
      end
      
    end
  end
end