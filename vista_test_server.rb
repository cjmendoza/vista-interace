require 'socket' # Get sockets from stdlib
require 'timeout'

# Copyright Vidaguard 2013
ACK = "MSH|^~\&|Orchard|Lab|HIS|hostSystem|20030917141001||ACK|4690|P|2.3
  MSA|AA|dfx20030917141003|message text\n"
PORT=2000

puts "Vista Labs Server Starting"


def self.send_results(rec)
  begin
    client = TCPSocket.new('localhost', 2001)
    rec.each do |msg|
      puts "Server - Sending result #{Time.new.strftime("%S%L")}"
      out = msg.gsub('OBX|', "OBX|1|NM|HostCode^Patient weight||175||||||F|||" << Time.new.strftime("%Y%m%d%H%M%S%L") <<"||")
      segs = out.split("\r")
      client.puts(11.chr.to_s)
      segs.each do |seg|
        client.puts(seg)
      end
      client.puts(28.chr.to_s)
      input = client.recv(2048)
      puts "Bad result ack #{input}" unless input.index('MSA|AA')
    end
  rescue
    puts "Cannot send result - #{$!}"
  end
end

# Author: Claudio Mendoza
server = TCPServer.open(PORT) # Socket to listen on port 2000
loop do
  begin
    client = server.accept # Wait for a client to connect
    rec = []
    loop do # Servers run forever
      input = ""
      Timeout::timeout(20) do
        loop do
          inp = client.gets
          break if inp.ord == 28
          input += inp unless inp.ord == 11
        end
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

      unless rec.empty?
        send_results(rec)
        rec = []
      end
    end
  rescue Timeout::Error
    puts "Server input timeout"
  rescue
    puts "Error in server reading #{$!}"
  end
  client.close
end
