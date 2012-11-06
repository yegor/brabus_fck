# encoding: utf-8

module BrabusStress
  module Steps
    module Geo
      
      def geocode_direct(term)
        send_data :path => "geo/geocoding/direct/", :payload => {:latitude => 53.93935048492061, :longitude => 27.57550346667652, :term => "Некрасова #{term.to_i + 1}"}
        wait_reply "geo/geocoding/direct/success"
      end
      
      def location
        send_data :path => "users/profile/location", :payload => {:location_container => {:lat => 53.93935048492061, :lng => 27.57550346667652}}
        wait_reply "users/profile/location/success"
      end
    
    end
  end
end