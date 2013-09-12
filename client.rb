require 'socket' # Get sockets from stdlib
require 'timeout'
require 'mysql'
ACK = "MSH|^~\&|Vidaguard|Careflow1|Orchard|Lab|_time_||ACK|4690|P|2.3
MSA|AA|_control_id_|_message_\n"
ACK_TIMEOUT = 10
RSLTS_TIMEOUT = 60

class Client
# Author: Claudio Mendoza
# Copyright Vidaguard 2013

  def initialize(name, send_min = 10)
    @name = name
    @send_min = send_min
  end

  def start
    puts 'Vidaguard Client Starting...'
    connect_to_db
    #Start the process to read from outgoing orders to send
    rows = @dbh.query("select * from interfaces where name = '#{@name}'")
    rows.each_hash do |rv| #should be only one row
      @host = rv['conn_addr']
      @port = rv['conn_port']
      @interface_id = rv['id']
      connect_to_socket
      loop do #this is main ongoing loop to gather messages to send.
        inputs = @dbh.query("select * from interface_outgoings where interface_id = #{@interface_id}")
        puts "Sending #{inputs.num_rows} orders"
        results = nil
        if inputs.num_rows > 0
          inputs.each_hash do |vals|
            results = transmit(vals)
          end
        end
        #wait to see if there are any results
        puts "Looking for results for #{RSLTS_TIMEOUT} seconds..."
        receive_results unless results
              #sleep @send_min.to_i * 60
      end
    end
  ensure
    @sock.close
    @dbh.close
    raise $!
  end


  def connect_to_db
    begin
      # connect to the MySQL server
      @dbh = Mysql.new('localhost', 'root', '', 'careflow')
    rescue Mysql::Error => e
      puts "An error occurred"
      puts "Error code:    #{e.errno}"
      puts "Error message: #{e.error}"
    end
    puts 'Connected to db'
  end

  def store_order_result(msg)
    del = 11.chr.to_s << 28.chr.to_s
    msg.delete!(del)
    @dbh.query("insert into interface_incomings(interface_id, data ,created_at) values
                 (#{@interface_id}, '#{msg}', '#{Time.new.utc}')")
  end

  def transmit(vals)
    results = nil
    begin
      results = send_msg(vals['data'])
      @dbh.query("insert into interface_logs(req_id, ancillary_id, data ,created_at) values
                 ('#{vals['req_id']}', #{vals['ancillary_id']}, '#{vals['data']}', '#{Time.new.utc}')")
      @dbh.query("delete from interface_outgoings where req_id = '#{vals['req_id']}'")
    rescue
      puts "Error transmit #{$!}"
    end
    results
  end

  def connect_to_socket(re_try_secs = 10)
    begin
      @sock = TCPSocket.new(@host, @port)
    rescue
      puts "Cannot connect #{$!}"
      sleep re_try_secs
      retry
    end
  end

  def send_msg(msg)
    read = ""
    out = 11.chr.to_s << msg << 28.chr.to_s << "\r\n"
    re_send = 0
    begin
      until read.index("MSA|AA") || re_send > 10
        puts "Client re-send #{re_send} - read = #{read} size: #{read.length}" if re_send > 0
        @sock.puts(out)
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

        re_send += 1
      end
    rescue
      puts "Message send failed - connecting again (send_msg) #{$!}"
      connect_to_socket
    end
    #puts "Exiting send"
  end

  def receive_results(message = nil)
    loop do
      begin
        unless message
          ready = IO.select([@sock], nil, nil, RSLTS_TIMEOUT)
          if ready
            message = @sock.recv(2048)
          else
            puts "Done looking for results! #{Time.new.strftime("%S%L")}"
            return message
          end
        end
        puts "Client - Result #{Time.new.strftime("%S%L")} #{message}"
        if message.index('OBX')
          store_order_result(message) if message.length > 1
          ack = ACK.gsub('_time_', Time.new.strftime("%S%L"))
          out = 11.chr.to_s << ack << 28.chr.to_s << "\r\n"
          @sock.puts(out)
        else
          puts "Bad result message - ignoring #{message}"
          return
        end
      rescue
        puts "Error reading result #{$!}"
      end
      message = nil
    end
  end

end