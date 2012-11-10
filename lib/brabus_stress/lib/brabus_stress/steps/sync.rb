module BrabusStress
  module Steps
    module Sync
      def sync_delta(memo = nil, &block)
        sync(self, block) do |runner|
          runner.send_data :path => "sync/delta", :payload => {}
          runner.wait_reply "sync/delta/success"
          runner.log_server_data
        end
      end
    end
  end
end
