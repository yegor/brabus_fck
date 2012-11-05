module BrabusStress
  class Runner
    include BrabusStress::Steps::Connection
    include BrabusStress::Steps::Auth
    include BrabusStress::Steps::LiveFeed
    include BrabusStress::Steps::Geo
    include BrabusStress::Steps::Sync
    
    attr_accessor :config, :logger, :benchmark
    
    def initialize
      @config = BrabusStress::Config.new
      @logger = Logger.new STDOUT
    end
  end
end