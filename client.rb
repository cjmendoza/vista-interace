require 'socket' # Get sockets from stdlib
require './database'
require 'timeout'
require 'mysql'
ACK = "MSH|^~\&|Vidaguard|Careflow1|Orchard|Lab|_time_||ACK|4690|P|2.3
MSA|AA|_control_id_|_message_\n"
ACK_TIMEOUT = 10
POLL_TIMEOUT = 10

class Client
# Author: Claudio Mendoza
# Copyright Vidaguard 2013

  def self.send_orders(name, send_min)
    Client.new(name, send_min).start
  end

  def initialize(name, send_min = 10)
    @name = name
    @send_min = send_min
  end

  def start
    puts 'Vidaguard Client Starting...'
    @host = '10.11.2.11' #rv['conn_addr']
    @port = 37055 #rv['conn_port']
    connect_to_socket
    @dbh = Database.connect

    #Start receive process
    #Start the process to read from outgoing orders to send
    rows = @dbh.query("select * from interfaces where name = '#{@name}'")
    rows.each_hash do |rv| #should be only one row

      @interface_id = rv['id']

      loop do #this is main ongoing loop to gather messages to send.
        inputs = @dbh.query("select * from interface_outgoings where interface_id = #{@interface_id}")
        puts "Sending #{inputs.num_rows} orders"
        results = nil
        if inputs.num_rows > 0
          inputs.each_hash do |vals|
            results = transmit(vals)
          end
        end
        #wait
        puts "Poll timeout #{POLL_TIMEOUT} seconds..."
        sleep POLL_TIMEOUT
      end
    end
  ensure
    @sock.close
    @dbh.close
    raise $!
  end

  def transmit(vals)
    results = nil
    begin
      results = send(vals['data'])
      @dbh.query("insert into interface_logs(req_id, ancillary_id, data ,created_at) values
                 ('#{vals['req_id']}', #{vals['ancillary_id']}, '#{vals['data']}', '#{Time.new.utc}')")
      @dbh.query("delete from interface_outgoings where req_id = '#{vals['req_id']}'")
    rescue
      puts "Error transmit #{$!}"
    end
    results
  end

  def connect_to_socket(re_try_secs = 10)
    #socket.setsockopt(Socket::SOL_SOCKET, Socket::SO_KEEPALIVE, true)
    begin
      @sock = TCPSocket.new(@host, @port)
      puts "#{Time.now} - Connected socket to host: #{@host} port: #{@port}"
    rescue
      puts "#{Time.now} - Cannot connect-> #{$!} host: #{@host} port: #{@port} - retrying in #{re_try_secs} seconds"
      sleep re_try_secs
      retry
    end
  end

  def send(msg)
    read = ""
    re_send = 0
    out = 11.chr.to_s + msg + 28.chr.to_s + "\r"
    until read.index("MSA|AA") || re_send > 10
      begin
        puts "Client re-send #{re_send} - read = #{read} size: #{read.length}" if re_send > 0
        @sock.puts(out)

        #segs = msg.split("\r")
        #segs.each do |seg|
        #  @sock.puts(seg)
        #end
        #@sock.puts(28.chr.to_s + '\r')
        puts "Client sent #{out.length} #{Time.new.strftime("%S%L")}"

        loop do
          ready = IO.select([@sock], nil, nil, ACK_TIMEOUT)
          if ready
            read = @sock.recv(2048)
            puts "Client get #{read.length} #{Time.new.strftime("%S%L")}"
            #return result to let know it was just processed
            return receive_results(read) if read.index('OBX')
            break
          else
            puts "No server response! Timed out after #{ACK_TIMEOUT} secs"
          end
        end

      rescue
        puts "Message send failed - connecting again (send_msg) #{$!}"
        connect_to_socket
        re_send += 1
      end
    end
    #puts "Exiting send"
  end

end