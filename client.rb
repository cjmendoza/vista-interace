require 'socket' # Get sockets from stdlib
require './database'
require 'timeout'
require 'mysql'
require 'logger'

ACK = "MSH|^~\&|Vidaguard|Careflow1|Orchard|Lab|_time_||ACK|4690|P|2.3
MSA|AA|_control_id_|_message_\n"
ACK_TIMEOUT = 10
POLL_TIMEOUT = 10

class Client
# Author: Claudio Mendoza
# Copyright Vidaguard 2013

  def self.send_orders(name, host, port, send_min, debug = false)
    Client.new(name, host, port, send_min, debug).start
  end

  def initialize(name, host, port, send_min = 10, debug)
    @name = name
    @host = host
    @port = port
    @send_min = send_min

    if debug
      @logger = Logger.new $stdout
      @logger.level = Logger::DEBUG
    else
      @logger = Logger.new File.new('../orders.log', "a"), 'weekly'
    end
  end

  def start
    @logger.info "Vidaguard Client Starting...#{Time.now}"

    @dbh = Database.connect(@logger)

    #Start receive process
    #Start the process to read from outgoing orders to send
    rows = @dbh.query("select * from interfaces where name = '#{@name}'")
    rows.each_hash do |rv| #should be only one row
      @interface_id = rv['id']
    end
    loop do #this is main ongoing loop to gather messages to send.
      inputs = @dbh.query("select * from interface_outgoings where interface_id = #{@interface_id}")
      results = nil
      if inputs.num_rows > 0
        @logger.info "Sending #{inputs.num_rows} orders"
        inputs.each_hash do |vals|
          results = transmit(vals)
        end
      end
      #wait
      @logger.debug "Waiting DB read poll timeout #{POLL_TIMEOUT} seconds..."
      sleep POLL_TIMEOUT
    end
  ensure
    @sock.close if @sock
    @dbh.close if @dbh
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
      @logger.error "Error transmit #{$!}"
    end
    results
  end

  def connect_to_socket(re_try_secs = 10)
    #socket.setsockopt(Socket::SOL_SOCKET, Socket::SO_KEEPALIVE, true)
    begin
      @sock = TCPSocket.new(@host, @port)
      @logger.info "#{Time.now} - Connected socket to host: #{@host} port: #{@port}"
    rescue
      @logger.warn "#{Time.now} - Cannot connect-> #{$!} host: #{@host} port: #{@port} - retrying in #{re_try_secs} seconds"
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
        @logger.warn "Client re-send #{re_send} - read = #{read} size: #{read.length}" if re_send > 0
        @sock.puts(out)

        @logger.debug "Client sent #{out.length} #{Time.new.strftime("%S%L")}"

        loop do
          ready = IO.select([@sock], nil, nil, ACK_TIMEOUT)
          if ready
            read = @sock.recv(2048)
            @logger.debug "Client get #{read.length} #{Time.new.strftime("%S%L")}"
            #return result to let know it was just processed
            return receive_results(read) if read.index('OBX')
            break
          else
            @logger.warn "No server response! Timed out after #{ACK_TIMEOUT} secs"
          end
        end

      rescue
        @logger.error "Message send failed - connecting again (send_msg) #{$!}"
        connect_to_socket
        re_send += 1
      end
    end
    @logger.info "Exiting send #{Time.now}"
  end

end