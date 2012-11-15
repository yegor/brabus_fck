require 'json'
require 'socket'
require 'openssl'
require 'timeout'

class Handler < EventMachine::Connection
  attr_accessor :on_connect, :on_data, :on_disconnect
  
  def post_init
    start_tls
  end
  
  def receive_data(data)
    on_data.try(:call, data)
  end
  
  def ssl_handshake_completed
    on_connect.try(:call)
  end
  
  def comm_inactivity_timeout
    30.0
  end

  def unbind
    on_disconnect.try(:call)
  end
  
end

module BrabusStress
  module Steps
    module Connection
      attr_accessor :no_ssl_socket, :socket, :the_rest
      
      def close_connection(memo = nil, &block)
        # @socket.on_disconnect = lambda do
        #   log_disconnected#(&block)
        # end
        
        @socket.close_connection
        block.call
      end
      
      def open_connection(server = @config.server, &block)
        server.symbolize_keys!
        @socket = ::EventMachine.connect server[:host], server[:port], Handler
        
        @socket.on_connect = lambda do 
          log_connected#(&block)
        end
        
        @socket.on_disconnect = lambda do
          log_disconnected
        end
        
        block.call
      end
      
      def log_server_data(memo = nil, &block)
        logger.info "!action | #{memo['reply_to']} | #{(Time.now.utc - memo[:completed_in].to_f).strftime "%H:%M:%S:%L"} | \t %3.6f" % memo['completed_in']
        block.call
      end
      
      def log_connected#(memo = nil, &block)
        @logger.info "connection | #{Time.now.utc.strftime "%H:%M:%S:%L"} | 1+"
        # block.call
      end
      
      def log_disconnected#(memo = nil, &block)
        @logger.info "connection | #{Time.now.utc.strftime "%H:%M:%S:%L"} | 1-"
        # block.call
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
          begin
            @the_rest = @the_rest.to_s + data

            while not the_rest.nil?
              @the_rest = @current_packet.append(@the_rest)

              if @current_packet.parsed?
                data = @current_packet.chunks.first.data
                @current_packet = BrabusStress::Cpacket::Packet.new

                block.call(JSON.parse(data)) if data.index('"reply_to":"' + reply_to + '"')
              end
            end
          rescue => e
            @logger.info "#{e.message}"
          ensure
            @logger.flush
          end
        end
      end   
    end
  end
end