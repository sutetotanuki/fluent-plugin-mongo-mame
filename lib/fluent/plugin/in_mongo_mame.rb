module Fluent
  class MongoMame < Input
    class InteractiveSleep
      def wait(seconds)
        @l, @r = IO.pipe
        IO.select([@l], nil, nil, seconds)
        [@l, @r].map(&:close) rescue IOError
      end
      
      def interupt
        if @r
          @r.close rescue IOError
        end
      end
    end

    class Enqueuer
      def initialize(queue)
        @queue = queue
      end

      def push(string)
        @queue.push string
      end
    end
    
    Plugin.register_input("mongo_mame", self)
    
    require 'mongo'
    require 'drb/drb'
    
    config_param :tag,          :string,  default: "debug"
    config_param :tag_key,      :string,  default: nil
    config_param :data_type,    :string,  default: "server_status,current_op"
    config_param :run_interval, :integer, default: 5
    
    DATA_TYPES = [
      "server_status",
      "current_op",
    ]
    
    STOP = 0x01
    
    def configure(conf)
      super
      @queue = Queue.new
      @run_data_types = data_type.split(",").compact
    end
    
    def start
      super
      # TODO: Connection infomation from config.
      @client = Mongo::Connection.new('localhost', 27017)
      
      @interactive_sleep = InteractiveSleep.new
      @drb_server = DRb::DRbServer.new("druby://localhost:11875", Enqueuer.new(@queue))
      
      @schedule_thread = Thread.new(&method(:schedule_queue))
      @run_thread = Thread.new(&method(:run))
    end
    
    def schedule_queue
      until @finished
        @run_before = Time.now
        @run_data_types.each do |data_type|
          @queue << data_type
        end
        
        wait_time = @run_interval - (Time.now - @run_before)
        @interactive_sleep.wait(wait_time) if wait_time > 0
      end
      
      @queue << STOP
    end
    
    def run
      while task = @queue.pop
        break if task == STOP

        # TODO: log receiving unregistered task
        self.__send__(task, @client) if respond_to?(task)
      end
      
      @client.close
    end
    
    def shutdown
      @finished = true
      @interactive_sleep.interupt
      @drb_server.stop_service
      @run_thread.join
    end
    
    def server_status(client)
      record = client["test"].command({ serverStatus: true})
      Engine.emit(tag + ".server_status", Engine.now, record)
    end
    
    def current_op(client)
      record = client["test"]["$cmd.sys.inprog"].find_one
      Engine.emit(tag + ".current_op", Engine.now, record)
    end
  end
end
