module BrabusStress
  module Steps
    module LiveFeed
      
      def post_to_live_feed(smth = "")
        send_data(:path => "messages/live_feed/create#{smth}",
                  :payload => {:message => {:message => "Testing live feed post"},
                               :marker => {:lat => 53.93950240691559, :lng => 27.5753717869777, :kind => "message"}
                              })
        # wait_reply "messages/live_feed/create/success"
      end
    
    end
  end
end