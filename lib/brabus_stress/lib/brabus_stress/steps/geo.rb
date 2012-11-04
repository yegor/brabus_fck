module BrabusStress
  module Steps
    module Geo
      
      def location
        send_data :path => "users/profile/location", :payload => {:location_container => {:lat => 53.93935048492061, :lng => 27.57550346667652}}
        wait_reply "users/profile/location/success"
      end
    
    end
  end
end