# encoding: utf-8

module BrabusStress
  module Steps
    module Geo
      
      def geocode_direct(memo = nil, &block)
        sync(self, block) do |runner|
          runner.send_data :path => "geo/geocoding/direct/", :payload => {:latitude => BrabusStress.random_latitude, :longitude => BrabusStress.random_longitude, :term => BrabusStress::GEOCODE_TERM}
          runner.wait_reply "geo/geocoding/direct/success"
          runner.log_server_data
        end
      end
      
      def location(memo = nil, &block)
        sync(self, block) do |runner|
          runner.send_data :path => "users/profile/location", :payload => {:location_container => {:lat => BrabusStress.random_latitude, :lng => BrabusStress.random_longitude}}
          runner.wait_reply "users/profile/location/success"
          runner.log_server_data
        end
      end
    
    end
  end
end