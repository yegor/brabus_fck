module BrabusStress
  module Scenarios
    class Auth
      extend BrabusStress::Sync
      
      def self.run!(memo = nil, &block)
        sync(BrabusStress::BenchmarkProxy.new(BrabusStress::Runner.new, self), block) do |runner|
          runner.connect
          runner.disconnect
          runner.balance           
           (BrabusStress::LOOP_COUNT / 5).to_i.times do
             runner.signup
             runner.confirm
             runner.login
             runner.sync_delta
             runner.logout
           end
           runner.disconnect
         end
      end
      
    end
  end
end