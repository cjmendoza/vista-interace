require './web_api'
require 'thread'


#Run host program to start client and server to send/receive orders
#loop{
  request = WebApi.assign_order(2345, 'labs', 'vista_labs')
puts "Assigning order"
  sleep 21
  result = WebApi.order_result(2345, request['req_id'])
#  WebApi.view_orders(2345, 'labs', 'vista_labs')
  putc('.'.ord)
#  sleep 10
#}
puts result