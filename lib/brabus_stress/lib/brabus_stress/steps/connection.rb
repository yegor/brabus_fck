require 'json'
require 'socket'
require 'openssl'
require 'timeout'

class Handler < EventMachine::Connection
  attr_accessor :on_connect, :on_data
  
  def post_init
    puts "Starting TLS"
    start_tls
  end
  
  def receive_data(data)
    on_data.try(:call, data)
  end
  
  def ssl_handshake_completed
    p "connected"
    on_connect.try(:call)
  end

  def unbind
    p 'connection closed'
  end
  
end

module BrabusStress
  module Steps
    module Connection
      attr_accessor :no_ssl_socket, :socket, :the_rest
      
      def close_connection(memo = nil, &block)
        @socket.close_connection
        block.call
      end
      
      def open_connection(server = @config.server, &block)
        server.symbolize_keys!
        @socket = ::EventMachine.connect server[:host], server[:port], Handler
        @socket.on_connect = block
      end
      
      def log_connected(memo = nil, &block)
        @logger.info "connection | #{Time.now.utc.strftime "%H:%M:%S:%L"} | 1+"
        block.call
      end
      
      def log_disconnected(memo = nil, &block)
        @logger.info "connection | #{Time.now.utc.strftime "%H:%M:%S:%L"} | 1-"
        block.call
      end
      
      def send_data(data, &block)
        packet = BrabusStress::Cpacket::Packet.new(data.to_json)
        @socket.send_data(packet.pack)
        yield
      end   
      
      def wait_reply(reply_to, &block)
        @current_packet ||= BrabusStress::Cpacket::Packet.new
        @the_rest ||= ""
                
        @socket.on_data = lambda do |data|
          @the_rest = @the_rest.to_s + data
                  
          while not the_rest.nil?
            @the_rest = @current_packet.append(@the_rest)
                    
            if @current_packet.parsed?
              json = JSON.parse(@current_packet.chunks.first.data)
              @current_packet = BrabusStress::Cpacket::Packet.new
                      
              block.call(json) if json['reply_to'] == reply_to
            end
          end
        end
      end   
    end
  end
end