require 'socket' # Get sockets from stdlib
require 'timeout'

# Copyright Vidaguard 2013
ACK = "MSH|^~\&|Orchard|Lab|HIS|hostSystem|20030917141001||ACK|4690|P|2.3
  MSA|AA|dfx20030917141003|message text\n"
PORT=2000

puts "Vista Labs Server Starting"


def self.send_results(client, rec)
  rec.each do |input|
    puts "Server - Sending result #{Time.new.strftime("%S%L")}"
    out = input.gsub('OBX|', "OBX|1|NM|HostCode^Patient weight||175||||||F|||" << Time.new.strftime("%Y%m%d%H%M%S%L") <<"||")
    client.puts(out) # Send order result
    input = client.recv(2048)
    puts "Bad result ack #{input}" unless input.index('MSA|AA')
  end
end

# Author: Claudio Mendoza
server = TCPServer.open(PORT) # Socket to listen on port 2000
client = server.accept # Wait for a client to connect
rec = []
input = ""
loop do # Servers run forever
  begin
    Timeout::timeout(20) do
      input = client.recv(2048)
    end
    puts "Server - get #{input.length} #{Time.new.strftime("%S%L")}"
    if input.index('OBR')
      client.puts(ACK) # Send the time to the client
      puts "Server - sending ACK #{ACK.length} #{Time.new.strftime("%S%L")}"
      rec << input
    else
      puts "Bad message #{input}"
      raise "Read 0 chars" if input.length == 0
    end
  rescue Timeout::Error
    unless rec.empty?
      send_results(client, rec)
      rec = []
    end
  rescue
    puts "Error in server #{$!}"
    client.close # Disconnect from the client
  end
end
