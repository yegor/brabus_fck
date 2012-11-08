module BrabusStress
  # Configured for the center of London with a range factor set to the city radius
  USER_GROUP        = "london"
  LATITUDE          = 51.51130657591914
  LONGITUDE         = -0.10625839233398438
  
  RANGE_FACTOR_LAT  = 0.1
  RANGE_FACTOR_LNG  = 0.25
  
  GEOCODE_TERM      = "Waterloo"
  
  LOOP_COUNT        = 5
  
  THREADS_COUNT     = 40
  
  def self.random_latitude
    BrabusStress::LATITUDE + (Random.new.rand(BrabusStress::RANGE_FACTOR_LAT / 2.0) * 2 - BrabusStress::RANGE_FACTOR_LAT)
  end
  
  def self.random_longitude
    BrabusStress::LONGITUDE + (Random.new.rand(BrabusStress::RANGE_FACTOR_LNG / 2.0) * 2 - BrabusStress::RANGE_FACTOR_LNG)
  end
end