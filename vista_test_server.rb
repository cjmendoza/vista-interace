require 'socket' # Get sockets from stdlib
require 'timeout'

# Copyright Vidaguard 2013
ACK = "MSH|^~\&|Orchard|Lab|HIS|hostSystem|20030917141001||ACK|4690|P|2.3
  MSA|AA|dfx20030917141003|message text\n"
PORT=2000

puts "Vista Labs Server Starting"


def self.send_results(client)
  2.times do
    puts "Server - Sending result #{Time.new.strftime("%S%L")}"
    obx = "OBX|1|NM|HostCode^Patient weight||175||||||F|||" << Time.new.strftime("%Y%m%d%H%M%S%L") <<"||\n"
    client.puts(obx) # Send order result
    input = client.recv(2048)
    puts "Bad result ack #{input}" unless input.index('MSA|AA')
  end
end

# Author: Claudio Mendoza
server = TCPServer.open(PORT) # Socket to listen on port 2000
client = server.accept # Wait for a client to connect
count = 3
loop do # Servers run forever
  input = ""
  begin
    Timeout::timeout(20) do
      input = client.recv(2048)
    end
    puts "Server - get #{input.length} #{Time.new.strftime("%S%L")}"
    if input.index('OBR')
      client.puts(ACK) # Send the time to the client
      puts "Server - sending ACK #{ACK.length} #{Time.new.strftime("%S%L")}"
    else
      puts "Bad message #{input}"
      raise "Read 0 chars" if input.length == 0
    end
  rescue Timeout::Error
    count += 1
    if count > 3
      send_results(client)
      count = 0
    end
  rescue
    puts "Error in server #{$!}"
    client.close # Disconnect from the client
  end
end
