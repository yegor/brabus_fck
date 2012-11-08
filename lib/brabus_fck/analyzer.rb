require 'csv'

module BrabusFck
  class Analyzer
    ACTION_REGEXP     = /.+\|\s(\w+)\s\|\s(.+?)\s.+?(\d+\.\d+)\)$/i
    CONNECTION_REGEXP = /.+\|\s(.+?)\s\|.+?1([\+|-])$/i
    
    attr_accessor :stats, :connections
    
    def initialize
      @stats  = {}
      @connections = []
      parse_results
    end
    
    def parse_results
      connections_deltas = []
      min_time = Time.now + 1.year
      max_time = Time.now - 1.year
      
      Dir.glob(File.expand_path("results/**/*.log", BrabusFck.app_root)) do |file|
        File.open(file).each do |line|
          if matchdata = line.match(ACTION_REGEXP)
            action = matchdata[1]
            time = Time.strptime matchdata[2], "%H:%M:%S:%L"
            benchmark = matchdata[3].to_f
            
            @stats[action.to_sym] ||= []
            @stats[action.to_sym] << {:time => time, :benchmark => benchmark}
          end
          
          if matchdata = line.match(CONNECTION_REGEXP)
            time = Time.strptime matchdata[1], "%H:%M:%S:%L"
            delta = "#{matchdata[2]}1".to_i
            
            min_time = time if time < min_time
            max_time = time if time > max_time
            
            connections_deltas << {:time => time, :delta => delta}
          end
        end
      end
      
      sort = Proc.new {|x,y| x[:time].to_f <=> y[:time].to_f }
      
      @stats.each {|action, timestamps| timestamps.sort! &sort}
      connections_deltas.sort! &sort
      
      # Fulfill batches array with 1 second step timestamps
      batches = []
      batches << min_time
      (max_time - min_time).to_i.times {
        batches << batches.last + 1.second
      }
      
      @connections = batches.inject({}) do |memo, batch_time|
        active_connections = connections_deltas.select {|delta| delta[:time] <= batch_time}.collect {|delta| delta[:delta]}.sum
        memo.merge(batch_time => active_connections)
      end
      
      CSV.open(File.expand_path("results/report.csv"), 'w') do |csv|
        csv << ["Time"] + @stats.keys.sort + ["Connections"]
        
        batches.each do |time|
           means = @stats.keys.sort.map do |name|
            stats = @stats[name]
            batch_stats = stats.select { |stat| stat[:time] <= time and stat[:time] > time - 1.second }
          
            if batch_stats.size > 0
              batch_stats.sum { |stat| stat[:benchmark].to_f } / batch_stats.size.to_f
            else
              "-"
            end
          end
          
          csv << [time.strftime("%H:%M:%S")] + means + [@connections[time]]
        end
      end   
    end
    
    def report!
      
    end
  end
end