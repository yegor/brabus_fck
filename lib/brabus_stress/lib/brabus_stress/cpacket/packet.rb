require 'tempfile'

module BrabusStress
  #  This module holds all packet-related stuff, designed to parse data in CPacket format online,
  #  store large chunks in temporary files, encode data into CPacket.
  #
  module Cpacket
    
    class Exception < ::Exception; end
    class InvalidPacketError < BrabusStress::Cpacket::Exception; end
    
    #  The base chunk representation, just storing the chunk size and chunk data.
    #
    class Chunk
      attr_accessor :size
      attr_accessor :data
      
      def initialize
        self.data = ""
      end
      
      #  Returns true if chunk has finished parsing itself.
      #
      def parsed?
        self.current_size == self.size
      end
      
      #  Appends a piece of data to current chunk.
      #
      #  * <tt>data</tt>:: Data to append to the current chunk.
      #
      def append(data)
        self.data << data
      end
      
      #  Returns the current size of chunk (probably just a part of it has been parsed yet).
      #
      def current_size
        self.data.size
      end
      
      #  For regular chunk, just removes the data.
      #
      def dismiss!
        self.data = ""
      end
      
      #  Returns a run-length encoded piece of data (4 bytes of length + data)
      #  representing this chunk.
      #
      def pack
        [ self.size ].pack("V") + self.data
      end
      
    end
    
    class FileChunk < Chunk
      
      attr_accessor :file
      attr_accessor :file_name
      attr_accessor :current_size
      
      #  Initializes the file chunk instance, filling in neccessary fields and creating Tempfile
      #  object to hold large data chunk.
      #
      def initialize
        super
        self.current_size = 0
        make_tempfile
      end
      
      #  Writes the data to temporary file, altering current size instance variable.
      #
      #  * <tt>data</tt>:: Data to append to file.
      #
      def append(data)
        self.current_size += data.size
        self.file << data
        
        if self.parsed?
          self.file.close
          self.file = nil
        end
      end
      
      #  For regular chunk, just removes the data.
      #
      def dismiss!
        File.unlink(self.file_name)
      end
      
      #  Returns a run-length encoded piece of data (4 bytes of length + data)
      #  representing this chunk.
      #
      def pack
        [ self.size ].pack("V") + File.open(self.file_name, "rb") { |f| f.read }
      end
      
    protected
      
      #  We have to kind of workaround as using Tempfile class will kill the file right
      #  after the object is GC'ed.
      #
      def make_tempfile
        f = ::Tempfile.new("uploaded-file")
        # we just want to have Tempfile generate a new path and check it for us
        path = f.path + ".#{ ''.object_id }"
        
        self.file = File.open(path, "w")
        self.file_name = path
        
        f.close(true)
      end
      
    end
    
    #  The wrapping class holding all chunks, the methods to append data and parse data online
    #  upon being received.
    #
    class Packet
      attr_accessor :chunks
      attr_accessor :number_of_chunks
      attr_accessor :version
      attr_accessor :retained
      attr_accessor :buffer
      
      def initialize(*chunks)
        if chunks.any?
          self.version = 1
          self.number_of_chunks = chunks.size
          self.chunks = chunks.map { |c| create_chunk_for_data(c) }
        else  
          self.chunks = [BrabusStress::Cpacket::Chunk.new]
          self.buffer = ""
        end
      end
      
      #  Appends data to current +Packet+ instance, creating a new chunk if neccessary.
      #  Returns nil in case all the data supplied has been eaten by parsing process,
      #  a +String+ in case the packet has finished eating data and can be passed further on for
      #  future processing. If the length of string is greater than 0 it means a new instance 
      #  of Packet shall be created and fed with the rest of data.
      #
      #  * <tt>data</tt>:: Data to append.
      #
      def append(data)
        self.buffer << data
        process_buffer
      end
      
      #  Returns true if the packet is fully parsed and ready to be passed onto processing.
      #
      def parsed?
        self.version and all_chunks? and current_chunk.parsed?
      end
      
      #  Returns binary representation of data wrapped into this packet.
      #
      def pack
        "\x01#{ self.chunks.size.chr }#{ self.chunks.map(&:pack).join }"
      end
      
      #  Retains the packet so that its content won't be removed by calling #release.
      #
      def retain
        self.retained = true
      end
      
      #  Attempts to release the packet.
      #
      def release
        release! unless self.retained
      end
      
      #  Forces releasing the packet.
      #
      def release!
        self.chunks.each &:dismiss!
      end
      
    protected
    
      #  Creates either a regular chunk or file chunk, depending on data being supplied.
      #
      #  * <tt>data</tt>:: Data to encode into a chunk.
      #
      def create_chunk_for_data(data)
        if data.is_a?(String) and data.size < 32.kilobytes
          return BrabusStress::Cpacket::Chunk.new.tap do |chunk|
            chunk.size = data.size
            chunk.append(data)
          end
        end
        
        if data.is_a?(String) and data.size >= 32.kilobytes
          return BrabusStress::Cpacket::FileChunk.new.tap do |chunk|
            chunk.size = data.size
            chunk.append(data)
          end
        end
        
        if data.is_a?(File)
          return BrabusStress::Cpacket::FileChunk.new.tap do |chunk|
            chunk.file.close
            FileUtils.cp(data.path, chunk.file_name)
            chunk.size = chunk.current_size = File.stat(data.path).size
          end
        end
      end
    
      #  Returns the chunk which is currently being parsed.
      #
      def current_chunk
        self.chunks.last
      end
      
      #  Returns true if all chunks have arrived (however, the last one might be incomplete).
      #
      def all_chunks?
        self.chunks.size == self.number_of_chunks
      end
    
      #  Processes internal buffer.
      #
      def process_buffer
        if parsed?
          return self.buffer 
        end
        
        if self.version.blank?
          return nil if buffer.size < 1
          
          #  parse out the current version of packet
          self.version, self.buffer = self.buffer[0].ord, self.buffer[1..-1]
          unless self.version == 1
            raise BrabusStress::Cpacket::InvalidPacketError.new("Version of packet is invalid, #{ self.version } supplied, 1 expected")
          end
        end
        
        if self.number_of_chunks.blank?
          return nil if buffer.size < 1
          
          #  parse out the number of chunks
          self.number_of_chunks, self.buffer = self.buffer[0].ord, self.buffer[1..-1]
          raise BrabusStress::Cpacket::InvalidPacketError.new("Invalid number of chunks: #{ self.number_of_chunks }") unless self.number_of_chunks > 0
        end
        
        if current_chunk.size.blank?
          return nil if buffer.size < 4
          
          #  parse the size of current chunk out
          current_chunk.size, self.buffer = self.buffer[0..3].unpack("V").first, self.buffer[4..-1]
          
          if use_file_chunk?
            self.chunks[-1] = BrabusStress::Cpacket::FileChunk.new.tap { |chunk| chunk.size = current_chunk.size }
          end
          
          raise InvalidPacketError.new("Invalid size of chunk ##{ self.chunks.size }: #{ current_chunk.size }") unless current_chunk.size > 0
        end
        
        unless current_chunk.parsed?
          bytes_to_append = [self.buffer.size, current_chunk.size - current_chunk.current_size].min
          current_chunk.append( self.buffer[0...bytes_to_append] )
          self.buffer = self.buffer[bytes_to_append..-1]
        end
        
        if current_chunk.parsed? and not all_chunks?
          self.chunks << BrabusStress::Cpacket::Chunk.new
        end
        
        return nil if (self.buffer.blank? and not parsed?)
        
        process_buffer
      end
      
      #  Returns true if the current chunk shall be replaced with a +FileChunk+ instance.
      #
      def use_file_chunk?
        chunks.size > 1
      end
    
    end
    
  end
  
end