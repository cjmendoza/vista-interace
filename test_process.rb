require './web_api'
require './server'
require './client'
require 'thread'


#set up server
#thr = Thread.new{Server.start(2000)} #emulates vista server
#cli = Thread.new{Client.start('vista_labs', '127.0.0.1', 2000)} #vidaguard client
#sleep 2
cli = Thread.new{Client.new('vista_orchard', 1).start}
#emulate orders being placed
loop{
  msg = WebApi.assign_order(2345, 'labs', 'vista_labs')
#  WebApi.view_orders(2345, 'labs', 'vista_labs')
  putc('.'.ord)
  sleep 10
}
