module BrabusStress
  # Configured for the center of London with a range factor set to the city radius
  USER_GROUP        = "LasVegas"
  LATITUDE          = 36.121236902880185
  LONGITUDE         = -115.17860412597656
  
  RANGE_FACTOR_LAT  = 0.1
  RANGE_FACTOR_LNG  = 0.25
  
  GEOCODE_TERM      = "Waterloo"
  
  LOOP_COUNT        = 30
  
  THREADS_COUNT     = 30
  
  def self.random_latitude
    BrabusStress::LATITUDE + (Random.new.rand(BrabusStress::RANGE_FACTOR_LAT / 2.0) * 2 - BrabusStress::RANGE_FACTOR_LAT)
  end
  
  def self.random_longitude
    BrabusStress::LONGITUDE + (Random.new.rand(BrabusStress::RANGE_FACTOR_LNG / 2.0) * 2 - BrabusStress::RANGE_FACTOR_LNG)
  end
end