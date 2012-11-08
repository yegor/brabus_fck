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
      @logger = Logger.new File.expand_path("logs/#{Process.pid}_#{UUID.generate.gsub("-", "")}.log", $BRABUS_STRESS_ROOT)
    end
  end
end