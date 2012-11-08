module BrabusStress
  module Steps
    module LiveFeed
      
      def post_to_live_feed(memo = nil, &block)
        sync(self, block) do |runner|
          runner.send_data(:path => "messages/live_feed/create",
                           :payload => {:message => {:message => "#{memo} Testing live feed post"},
                           :marker => {:lat => BrabusStress.random_latitude, :lng => BrabusStress.random_longitude, :kind => "message"}})
          runner.wait_reply "messages/live_feed/create/success"
        end
      end
    
    end
  end
end