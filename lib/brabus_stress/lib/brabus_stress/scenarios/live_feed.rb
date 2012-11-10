module BrabusStress
  module Scenarios
    class LiveFeed
      extend BrabusStress::Sync
      
      def self.run!(memo = nil, &block)
        sync(BrabusStress::BenchmarkProxy.new(BrabusStress::Runner.new, self), block) do |runner|
          runner.connect
          runner.balance
          runner.signup
          runner.confirm
          runner.login
          runner.sync_delta
          BrabusStress::LOOP_COUNT.times {|i| runner.post_to_live_feed(i)}
          runner.logout
          runner.disconnect
        end
      end

    end
  end
end