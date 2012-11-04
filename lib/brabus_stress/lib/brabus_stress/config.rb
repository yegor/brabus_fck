module BrabusStress
  class Config
    attr_accessor :server
    
    def initialize
      parse_config
    end
    
    protected
    
    def parse_config
      @server  = YAML.load_file(File.join($BRABUS_STRESS_ROOT, "config/server.yml")).symbolize_keys!
    end
  end
end