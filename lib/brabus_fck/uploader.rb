require 'find'

module BrabusFck
  class Uploader
    APPLICATION_PATH = File.join(BrabusFck.app_root, "lib")
    APPLICATION_NAME = "brabus_stress"
    ARCHIVE_PATH     = File.join(BrabusFck.app_root, "lib/brabus_stress.tar.gz")
    ARCHIVE_NAME     = "brabus_stress.tar.gz"
    RESULTS_PATH     = File.join(BrabusFck.app_root, "results")
    
    attr_accessor :config, :logger
    
    def initialize(config, logger)
      @config = config
      @logger = logger
    end
    
    def upload
      tar_app
        
      @logger.info "Uploading stress test application over FTP..."
              
      threads = []
      @config.servers.each do |server|
        threads <<  Thread.new {
          Net::SSH.start(server[:host], server[:user], :keys => config.keys) do |ssh|
            ssh.exec "rm -f #{ARCHIVE_NAME}"
            ssh.exec "rm -rf #{APPLICATION_NAME}"
            ssh.sftp.upload! ARCHIVE_PATH, ARCHIVE_NAME
            ssh.exec "tar xzf #{ARCHIVE_NAME}"
          end
        }
      end
        
      # Block until all file uplaods are completed
      threads.each {|thread| thread.join}
        
      @logger.info "Upload completed."
    end
      
    def tar_app
      @logger.info "Updating zip archive..."    
      system "tar --create --gzip --directory #{APPLICATION_PATH} --file #{ARCHIVE_PATH} #{APPLICATION_NAME}"
    end
      
    def download_logs
      @logger.info "Downloading results over FTP..."
              
      threads = []
      @config.servers.each do |server|
        FileUtils.mkdir_p File.join(BrabusFck.app_root, "results", server[:host])
        threads << Thread.new {
          Net::SFTP.start(server[:host], server[:user], :keys => config.keys) do |sftp|
            sftp.dir.glob("#{APPLICATION_NAME}/logs", "*.log") do |entry|
              sftp.download! "#{APPLICATION_NAME}/logs/#{entry.name}", "#{RESULTS_PATH}/#{server[:host]}/#{entry.name}"
            end
          end
        }
      end
        
      # Block until all file uplaods are completed
      threads.each {|thread| thread.join}
        
      @logger.info "Download completed."
    end
      
    def cleanup
        
    end

  end
end