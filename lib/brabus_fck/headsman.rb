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
    
    def dump_logs!
      @uploader.download_logs
    end
    
    protected
    
    def stress_test
      @logger.info "Starting stress test..."
      
      threads = []
      @config.servers.each { |server|
        threads << Thread.new {
          Net::SSH.start(server[:host], server[:user], :keys => @config.keys) do |ssh|
            ssh.exec "cd ~/brabus_stress && ./bin/stress"
          end
        }
      }
      
      threads.each {|thread| thread.join }
      @logger.info "Stress test completed"
      dump_logs!
    end
    
    def setup_remote_application
      @logger.info "Configuring stress application..."
      
      Net::SSH::Multi.start do |session|
        session.group :load_test do
          @config.servers.each do |server|
            session.use "#{server[:user]}@#{server[:host]}", :keys => @config.keys
          end
        end
        
        # session.with(:load_test).exec("bash -l -c 'cd brabus_stress && rvm 1.9.2 && bundle install'").wait
        session.with(:load_test).exec("bash -l -c 'cd brabus_stress && bundle install'").wait
      end
      
      @logger.info "Configuring completed."
    end
    
  end
end