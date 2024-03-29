require 'net/ssh/multi'
require 'net/sftp'

module BrabusFck
  class Headsman
    attr_accessor :config, :logger, :uploader
    
    def initialize
      @config = BrabusFck::Config.new
      @logger = Logger.new File.expand_path('log/headsman.log', BrabusFck.app_root)
      @uploader = BrabusFck::Uploader.new @config, @logger
    end
    
    def configure!
      @uploader.cleanup
      @uploader.upload
      setup_remote_application      
    end
    
    def execute!
      stress_test
    end
    
    def report!
      @analyzer = BrabusFck::Analyzer.new
      @analyzer.report!
    end
    
    def dump_logs!
      @uploader.download_logs
    end
    
    protected
    
    def stress_test
      @logger.info "Starting stress test..."
      
      Net::SSH::Multi.start do |session|
        session.group :load_test do
          @config.servers.each do |server|
            session.use "#{server[:user]}@#{server[:host]}", :keys => @config.keys  
          end
        end
        
        session.with(:load_test).exec("cd ~/brabus_stress && ./bin/stress")
        session.with(:load_test).exec("for i in {1..#{@config.config[:amount]}}; do PID=$i bash -c 'cd ~/brabus_stress && ./bin/stress' & done")
        
        # session.with(:load_test).exec("cd brabus_stress && bundle exec gem uninstall eventmachine --install-dir=/home/ubuntu/.bundler/ruby/1.9.1").wait
      end
      
      @logger.info "Stress test completed"
      dump_logs!
      report!
    end
    
    def setup_remote_application
      @logger.info "Configuring stress application..."
      
      Net::SSH::Multi.start do |session|
        session.group :load_test do
          @config.servers.each do |server|
            session.use "#{server[:user]}@#{server[:host]}", :keys => @config.keys
          end
        end
        
        session.with(:load_test).exec("cd brabus_stress && bundle install --deployment")
        # session.with(:load_test).exec("cd brabus_stress && bundle exec gem uninstall eventmachine --install-dir=/home/ubuntu/.bundler/ruby/1.9.1").wait
      end
      
      @logger.info "Configuring completed."
    end
    
  end
end