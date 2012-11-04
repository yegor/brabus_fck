require 'net/ssh/multi'
require 'net/sftp'

module BrabusFck
  class Headsman
    attr_accessor :config, :logger
    
    def initialize
      @config = BrabusFck::Config.new
      @logger = Logger.new File.expand_path('log/headsman.log', BrabusFck.app_root)
    end
    
    def execute!
      BrabusFck::Uploader.upload!(@config, @logger)
      
      Net::SSH::Multi.start do |session|
        session.group :load_test do
          @config.servers.each do |server|
            session.use "#{server[:user]}@#{server[:host]}", :keys => @config.keys
          end
        end
        
        session.with(:load_test).exec("bash -l -c 'cd brabus_stress && rvm 1.9.2 && bundle install'").wait
      end
      
      Net::SSH::Multi.start do |session|
        session.group :load_test do
          @config.servers.each do |server|
            session.use "#{server[:user]}@#{server[:host]}", :keys => @config.keys
          end
        end
        
        @config.servers.each do |server|
          server[:amount].to_i.times do |i|
            session.with(:load_test).exec "bash -l -c 'cd ~/brabus_stress && rvm 1.9.2 && ./bin/stress -d -P pids/#{i}.pid -l logs/#{i}.log'"
          end
        end
      end      
    end
    
    def upload_tests

    end
  end
end