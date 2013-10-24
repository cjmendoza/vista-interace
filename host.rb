require './client'
require './server'

client = Thread.new{Client.send_orders('vista_orchard', 1).start}
puts "Started Client to send orders..."
server = Thread.new{Server.receive_results('vista_orchard', 37056).start}
puts "Started Server to receive results..."

client.join
server.join

