require 'csv'
require 'benchmark'

module BrabusFck
  class Analyzer
    NET_ACTION_REGEXP     = /action.+\|\s(\w+)\s\|\s(.+?)\s+(\d+\.\d+)$/i
    SERVER_ACTION_REGEXP  = /!action.+\|\s(.+?)\s\|\s(.+?)\s+(\d+\.\d+)$/i
    CONNECTION_REGEXP     = /.+\|\s(.+?)\s\|.+?1([\+|-])$/i
    
    ACTIONS_MAP = {
      "connect"           => "balancing/move",
      "balance"           => "balancing/settled",
      "signup"            => "users/auth/signup/success",
      "confirm"           => "users/auth/signup/confirmed",
      "login"             => "users/auth/login/success",
      "geocode_direct"    => "geo/geocoding/direct/success",
      "location"          => "users/profile/location/success",
      "post_to_live_feed" => "messages/live_feed/create/success",
      "sync_delta"        => "sync/delta/success",
      "logout"            => "users/auth/logout/success"
      }.invert
    
    attr_accessor :stats, :connections
    
    def initialize
      @stats  = {}
      @server_stats = {}
      @connections_deltas = []
      @connections = []
      
      parse_results
      p Benchmark.measure { report! }
    end
    
    def parse_results
      connections_deltas = []
      @min_time = Time.now + 1.year
      @max_time = Time.now - 1.year
      
      Dir.glob(File.expand_path("results/**/*.log", BrabusFck.app_root)) do |file|
        File.open(file).each do |line|
          line.gsub!("\t", "")
          if matchdata = line.match(NET_ACTION_REGEXP)
            action = matchdata[1]
            time = Time.strptime matchdata[2], "%H:%M:%S:%L"
            benchmark = matchdata[3].to_f
            
            @stats[action.to_sym] ||= []
            @stats[action.to_sym] << {:time => time, :benchmark => benchmark}
          end
          
          if matchdata = line.match(SERVER_ACTION_REGEXP)
            action = matchdata[1]
            time = Time.strptime matchdata[2], "%H:%M:%S:%L"
            benchmark = matchdata[3].to_f

            @server_stats[ACTIONS_MAP[action].to_sym] ||= []
            @server_stats[ACTIONS_MAP[action].to_sym] << {:time => time, :benchmark => benchmark}
          end
          
          if matchdata = line.match(CONNECTION_REGEXP)
            time = Time.strptime matchdata[1], "%H:%M:%S:%L"
            delta = "#{matchdata[2]}1".to_i
            
            @min_time = time if time < @min_time
            @max_time = time if time > @max_time
            
            @connections_deltas << {:time => time, :delta => delta}
          end
        end
      end
      
      sort = Proc.new {|x,y| x[:time].to_f <=> y[:time].to_f }
      
      @stats.each {|action, timestamps| timestamps.sort! &sort}
      @server_stats.each {|action, timestamps| timestamps.sort! &sort}
      
      @connections_deltas.sort! &sort
    end
    
    #  Lugovsky solver
    #
    def solve
      
    end
        
    #  Creates CSV report with NET and server benchmarks
    #
    def report!
      # Fulfill batches array with 1 second step timestamps
      #
      batches = []
      @min_time = Time.at(@min_time.to_f.truncate + 0.999)
      batches << @min_time
      
      (@max_time - @min_time).to_i.times {
        batches << batches.last + 1.second
      }
      batches << batches.last + 1.second
      
      @keys = @stats.keys.sort.each(&:to_sym)
      @keys.delete(:disconnect)
      
      CSV.open(File.expand_path("results/report.csv"), 'w') do |csv|
        head = []
        @keys.each_with_index {|stat_name, index| head << "N #{stat_name}"; head << stat_name; head << "Server" }
        
        csv << ["Time"] + head + ["Connections"]
        # Calculate active connections per second
      
        net_bm = {}
        net_bm_count = {}
        net_bm_index = {}

        serv_bm = {}
        serv_bm_count = {}
        serv_bm_index = {}
        
        @keys.each { |stat_name| net_bm_index[stat_name] = 0; serv_bm_index[stat_name] = 0 }
        
        connections_index = 0
        
        batches.each_with_index do |batch, index|
          active_connections = 0
          for i in connections_index..(@connections_deltas.size - 1) do
            if @connections_deltas[i][:time].to_f <= batch.to_f
              active_connections += @connections_deltas[i][:delta]
            else
              connections_index = i
              break
            end
          
            if i == @connections_deltas.size-1
              connections_index = i + 1
              break
            end
          end
        
          @keys.each do |stat_name|
            net_bm[stat_name] = 0
            net_bm_count[stat_name] = 0
            
            for i in net_bm_index[stat_name]..(@stats[stat_name].size - 1) do
              if @stats[stat_name][i][:time].to_f <= batch.to_f
                net_bm[stat_name] += @stats[stat_name][i][:benchmark]
                net_bm_count[stat_name] += 1
              else
                net_bm_index[stat_name] = i
                break
              end
          
              if i == @stats[stat_name].size - 1
                net_bm_index[stat_name] = i + 1
                break
              end            
            end          
          end
          
          @keys.each do |stat_name|
            serv_bm[stat_name] = 0
            serv_bm_count[stat_name] = 0
            for i in serv_bm_index[stat_name]..(@server_stats[stat_name].size - 1) do
              if @server_stats[stat_name][i][:time].to_f <= batch.to_f
                serv_bm[stat_name] += @server_stats[stat_name][i][:benchmark]
                serv_bm_count[stat_name] += 1
              else
                serv_bm_index[stat_name] = i
                break
              end
          
              if i == @server_stats[stat_name].size - 1
                serv_bm_index[stat_name] = i + 1
                break
              end            
            end          
          end

          if index > 0
            @connections << active_connections + @connections[index - 1]
          else
            @connections << active_connections
          end
          
          result = []
          @keys.each_with_index do |stat_name, index|
            net_average = 0
            serv_average = 0
            net_average = (net_bm[stat_name] / net_bm_count[stat_name]) if net_bm_count[stat_name] > 0
            serv_average = (serv_bm[stat_name] / serv_bm_count[stat_name]) if serv_bm_count[stat_name] > 0
            
            result += ["#{net_bm_count[stat_name]}", "%3.4f"% net_average]
            result += ["%3.4f"% serv_average]
          end
          
          csv << [batch.strftime("%H:%M:%S")] + result.flatten + [@connections[index]]
        end
        
        head = []
        @keys.each_with_index {|stat_name, index| head << "N #{stat_name}"; head << stat_name; head << "Server" }
        
        csv << [" "] + head + ["Connections"]
      end
    end
  end
end