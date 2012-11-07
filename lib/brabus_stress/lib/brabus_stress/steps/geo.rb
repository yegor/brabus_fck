# encoding: utf-8

module BrabusStress
  module Steps
    module Geo
      
      def geocode_direct(term)
        send_data :path => "geo/geocoding/direct/", :payload => {:latitude => BrabusStress.random_latitude, :longitude => BrabusStress.random_longitude, :term => BrabusStress::GEOCODE_TERM}
        wait_reply "geo/geocoding/direct/success"
      end
      
      def location
        send_data :path => "users/profile/location", :payload => {:location_container => {:lat => BrabusStress.random_latitude, :lng => BrabusStress.random_longitude}}
        wait_reply "users/profile/location/success"
      end
    
    end
  end
end