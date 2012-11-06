require 'json'
require 'socket'
require 'openssl'
require 'timeout'

module BrabusStress
  module Steps
    module Connection
      attr_accessor :no_ssl_socket, :socket, :the_rest
      
      def disconnect!
        @no_ssl_socket.close
      end
      
      def connect!(server = @config.server)
        @no_ssl_socket = TCPSocket.new server[:host], server[:port]
        sslContext = OpenSSL::SSL::SSLContext.new
        @socket = OpenSSL::SSL::SSLSocket.new(@no_ssl_socket, sslContext)
        @socket.sync_close = true
        @socket.connect        
      end
      
      def log_connected
        @logger.info "connection | #{Time.now.utc.strftime "%H:%M:%S:%L"} | 1+"
      end
      
      def log_disconnected
        @logger.info "connection | #{Time.now.utc.strftime "%H:%M:%S:%L"} | 1-"
      end
      
      def send_data(data)
        packet = BrabusStress::Cpacket::Packet.new(data.to_json)
        @socket.write(packet.pack)
      end
      
      def wait_reply(reply_to)
        begin 
          timeout(20) do
            while true 
              current_packet = BrabusStress::Cpacket::Packet.new
              @the_rest = current_packet.append(@the_rest.to_s)
              
              while not current_packet.parsed?
                data = @socket.sysread(8192)
                @the_rest = current_packet.append(@the_rest.to_s + data)
              end
              
              data = JSON.parse(current_packet.chunks.first.data)
              return data if data['reply_to'] == reply_to
            end
          end
        rescue Timeout::Error
          puts "Time out error!"
        rescue EOFError
          puts "Connection closed!"
        end        
      end      
    end
  end
end