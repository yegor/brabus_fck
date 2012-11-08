module BrabusStress
  module Scenarios
    class Geocode
      extend BrabusStress::Sync
      
      def self.run!(memo = nil, &block)
        sync(BrabusStress::Runner.new, block) do |runner|
          runner.connect
          runner.signup_and_login
          runner.sync_delta
          BrabusStress::LOOP_COUNT.times {runner.geocode_direct}
          runner.logout
          # runner.disconnect
        end
      end

    end
  end
end