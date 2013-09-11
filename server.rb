require 'socket' # Get sockets from stdlib
class Server
# Copyright Vidaguard 2013
# Author: Claudio Mendoza
  ACK = "MSH|^~\&|Orchard|Lab|HIS|hostSystem|20030917141001||ACK|4690|P|2.3
MSA|AA|dfx20030917141003|message text\n"


  def self.start(port)
    puts "Vista Labs Server Starting"
    begin
      server = TCPServer.open(port) # Socket to listen on port 2000
      client = server.accept # Wait for a client to connect
      count = 0
      loop do # Servers run forever
        input = client.recv(2048)
#        puts "server get #{input.length}"
        if input.index('MSH')
          client.puts(ACK) # Send the time to the client
#          puts "server sending #{ACK.length}"
        else
          puts "Bad message #{input.length} - first char #{input[0].ord}"
        end
        count += 1
        if count > 5
          2.times do
            obx = "OBX|1|NM|HostCode^Patient weight||175||||||F|||" << Time.new.strftime("%Y%m%d%H%M%S%L") <<"||\n"
            client.puts(obx) # Send order result
            input = client.recv(2048)
            raise "No order ack" unless input.index('MSA|AA')
          end
          count = 0
        end
      end
    rescue
      puts "Error in server #{$!}"
      client.close # Disconnect from the client
    end
  end

  def self.test(port)
    puts "Vista Labs Server Starting"
    server = TCPServer.open(port) # Socket to listen on port 2000
    run = 1
    client = server.accept # Wait for a client to connect
    client.puts(Time.now.ctime) # Send the time to the client
    loop { # Servers run forever
      input = client.gets.chop
      client.puts "You said: #{ input }"
      puts input + run.to_s
      if input == 'stop'
        client.puts "Closing the connection. Bye! #{input}"
        client.close # Disconnect from the client
        client = server.accept # Wait for a client to connect
        client.puts(Time.now.ctime) # Send the time to the client
        run+=1
      end
    }
  end
end
