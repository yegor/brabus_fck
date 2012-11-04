module BrabusFck
  class Config
    attr_accessor :config, :servers, :keys
    
    def initialize
      parse_config
    end
    
    protected
    
    def parse_config
      @config  = YAML.load_file(File.join(BrabusFck.app_root, "config/servers.yml")).symbolize_keys!
      @servers = self.config[:servers].collect &:symbolize_keys!
      @keys    = @servers.collect {|server| server[:key]}.compact.collect {|key_name| File.expand_path("config/keys/#{key_name}", BrabusFck.app_root)}
    end
  end
end