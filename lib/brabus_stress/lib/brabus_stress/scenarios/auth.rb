module BrabusStress
  module Scenarios
    class Auth
      extend BrabusStress::Sync
      
      def self.run!(memo = nil, &block)
        sync(BrabusStress::Runner.new, block) do |runner|
           runner.connect
           (BrabusStress::LOOP_COUNT / 5).to_i.times do
             runner.signup_and_login
             runner.sync_delta
             runner.logout
           end
           runner.disconnect
         end
      end
      
    end
  end
end