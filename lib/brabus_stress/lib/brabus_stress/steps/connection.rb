require 'json'
require 'socket'
require 'openssl'
require 'timeout'

class Handler < EventMachine::Connection
  attr_accessor :on_connect, :on_data, :mutex, :current_packet, :the_rest
  
  def initialize
    self.mutex = Mutex.new
  end
  
  def post_init
    start_tls
  end
  
  def receive_data(data)
    on_data.try(:call, data)
  end
  
  def ssl_handshake_completed
    on_connect.try(:call)
  end

  def unbind
  end
  
end

module BrabusStress
  module Steps
    module Connection
      attr_accessor :no_ssl_socket, :socket
      
      def close_connection(memo = nil, &block)
        @socket.close_connection
        self.log_disconnected(memo, &block)
      end
      
      def open_connection(server = @config.server, &block)
        server.symbolize_keys!
        @socket = ::EventMachine.connect server[:host], server[:port], Handler
        @socket.on_connect = block
      end
      
      
      def log_server_data(memo = nil, &block)
        logger.info "!action | #{memo['reply_to']} | #{(Time.now.utc - memo[:completed_in].to_f).strftime "%H:%M:%S:%L"} | \t %3.6f" % memo['completed_in']
        block.call
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
        @socket.current_packet ||= BrabusStress::Cpacket::Packet.new
        @socket.the_rest ||= ""
                
        @socket.on_data = lambda do |data|
          EM.defer do
            @socket.mutex.synchronize do
              @socket.the_rest = @socket.the_rest.to_s + data
                  
              while not @socket.the_rest.nil?
                @socket.the_rest = @socket.current_packet.append(@socket.the_rest)
                    
                if @socket.current_packet.parsed?
                  json = JSON.parse(@socket.current_packet.chunks.first.data)
                  @socket.current_packet = BrabusStress::Cpacket::Packet.new
                      
                  puts "Got #{reply_to}!!!"
                      
                  EM.run { block.call(json) } if json['reply_to'] == reply_to
                end
              end
            end
          end
        end
      end   
    end
  end
end