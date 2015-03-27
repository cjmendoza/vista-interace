require './client'
require './server'


client = Thread.new{Client.send_orders('vista_orchard', '10.11.2.11', 37055, 1, ARGV[0]).start}
#client = Thread.new{Client.send_orders('vista_orchard', '10.3.4.21', 37055, 1).start}
puts "Started Client to send orders..."
# params interface, port, api_serv_addr
server = Thread.new{Server.receive_results('vista_orchard', 37056, '127.0.0.1', ARGV[0]).start}
puts "Started Server to receive results..."

client.join
server.join

