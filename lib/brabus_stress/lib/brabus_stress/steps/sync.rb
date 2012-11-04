module BrabusStress
  module Steps
    module Sync
      
      def sync_delta
        send_data :path => "sync/delta", :payload => {}
        wait_reply "sync/delta/success"
      end
    
    end
  end
end