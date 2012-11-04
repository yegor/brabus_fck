require 'find'

module BrabusFck
  class Uploader
    APPLICATION_PATH = File.join(BrabusFck.app_root, "lib")
    APPLICATION_NAME = "brabus_stress"
    ARCHIVE_PATH     = File.join(BrabusFck.app_root, "lib/brabus_stress.tar.gz")
    ARCHIVE_NAME     = "brabus_stress.tar.gz"
    
    class << self
      def upload!(config, logger)
        tar_app(logger)
        
        logger.info "Initiating upload over FTP..."
              
        threads = []
        config.servers.each do |server|
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
        
        logger.info "Upload completed..."
      end
      
      def tar_app(logger)
        logger.info "Updating zip archive..."    
        system "tar --create --gzip --directory #{APPLICATION_PATH} --file #{ARCHIVE_PATH} #{APPLICATION_NAME}"
      end
    
    end    

  end
end