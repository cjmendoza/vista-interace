require 'socket' # Get sockets from stdlib
require './database'
require 'json'
class Server
# Copyright Vidaguard 2013
# Author: Claudio Mendoza
  RSLTS_TIMEOUT = 20
  ACK = "MSH|^~\&|Orchard|Lab|HIS|hostSystem|20030917141001||ACK|4690|P|2.3
MSA|AA|dfx20030917141003|message text\n"

  def self.receive_results(interface, port)
    server = Server.new(interface, port)
    server.start
  end

  def initialize(interface, port)
    @interface = interface
    @port = port
  end

  def start
    @dbh = Database.connect
    rows = @dbh.query("select * from interfaces where name = '#{@interface}'")
    rows.each_hash do |rv| #should be only one row
      @interface_id = rv['id']
    end

    loop do
      server = TCPServer.open(@port) # Socket to listen on port
      puts "Accepting results in port #{@port}..."
      loop do
        client = server.accept # Wait for a client to connect
        message = []
        begin
          ready = IO.select([client], nil, nil, RSLTS_TIMEOUT)
          if ready
            loop do
              inp = client.gets
              break if inp.ord == 28
              message << inp.delete("\n") unless inp.ord == 11
            end
          else
            break
          end
          puts "Client - Result #{Time.new.strftime("%S%L")} #{message}"
          if message.length > 1
            store_order_result(message)
            ack = ACK.gsub('_time_', Time.new.strftime("%S%L"))
            out = 11.chr.to_s << ack << 28.chr.to_s << "\r\n"
            client.puts(out)
          else
            puts "Bad result message - ignoring #{message}"
            break
          end
        rescue
          puts "Error reading result #{$!}"
          break
        end
        client.close
      end
      server.close
    end
  end

  def store_order_result(msg)
    @dbh.query("insert into interface_incomings(interface_id, data ,created_at) values
                 (#{@interface_id}, '#{JSON.dump(msg)}', '#{Time.new.utc}')")
  end
end
