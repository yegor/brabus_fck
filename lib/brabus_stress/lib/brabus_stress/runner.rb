module BrabusStress
  class Runner
    include BrabusStress::Steps::Connection
    include BrabusStress::Steps::Auth
    include BrabusStress::Steps::LiveFeed
    include BrabusStress::Steps::Geo
    include BrabusStress::Steps::Sync
    
    attr_accessor :config, :logger
    
    def initialize
      @config = BrabusStress::Config.new
      # @logger = Logger.new File.expand_path('log/brabus_stress.log', $BRABUS_STRESS_ROOT)
    end
  end
end