require 'socket' # Get sockets from stdlib
require './database'
require "net/http"
require "uri"
require "net/https"
require 'json'
require 'logger'
require 'time'

class Server
# Copyright Vidaguard 2013
# Author: Claudio Mendoza
  attr_accessor :dbh, :logger, :interface_id
  RSLTS_TIMEOUT = 20
  ACK = "MSH|^~\\&|Vidaguard|Careflow1|Orchard|Lab|_time_||ACK|4690|P|2.3||AL|NE|US||\r
MSA|AA|_ref_id_|\r"

  def self.receive_results(interface, port, api_serv_addr, debug = false)
    server = Server.new(interface, port, api_serv_addr, debug)
    server.start
  end

  def initialize(interface, port, api_serv_addr, debug)
    @interface = interface
    @port = port
    @api_serv_addr = api_serv_addr

    if debug
      @logger = Logger.new $stdout
      @logger.level = Logger::DEBUG
    else
      @logger = Logger.new File.new('../results.log', 'a'), 'weekly'
    end
  end

  def start
    @logger.info "Vidaguard Results Server Starting...#{Time.now}"

    @dbh = Database.connect(@logger)
    rows = @dbh.query("select * from interfaces where name = '#{@interface}'")
    rows.each_hash do |rv| #should be only one row
      @interface_id = rv['id']
    end

    loop do
      @logger.info "Waiting on results port #{@port}..."
      server = TCPServer.open(@port) # Socket to listen on port
      @logger.info "Listening in port #{@port}..."
      client = server.accept # Wait for a client to connect
      @logger.info "Accepting results messages..."
      ready = IO.select([client], nil, nil, RSLTS_TIMEOUT)
      loop do
        message = ""
        begin
          if ready
            loop do
              inp = client.recv(1024)
              if inp
                @logger.debug("Got result #{inp.gsub("\r", '')}\n")
                message << inp

                if inp[-2, 1].ord == 28 #\x1C
                  @segs = message.split('|')
                  ref_id = @segs[9]
                  client.puts(prepare_ack(ref_id))
                  post_results(ref_id, message)
                  break
                end
              end
            end
          else
            post_old_results
            break
          end
          unless message.length > 1
            @logger.error "Bad result message - ignoring #{message}"
            break
          end
        rescue
          @logger.error "Error processing result #{$!}"
          break
        end
        client.close
      end
      server.close
    end
  end

  def prepare_ack(ref_id)
    ack = ACK.gsub('_time_', Time.new.strftime("%S%L"))
    ack.gsub!('_ref_id_', ref_id)
    out = 11.chr.to_s << ack << 28.chr.to_s << "\r\r"
    @logger.debug("ACK result #{out}")
    out
  end

  def store_order_result(ref_id, msg, posted_at = nil)
    @logger.debug("Storing result #{Time.new.strftime("%M:%S:%L")} #{msg.length} bytes")
    @dbh.query("insert into interface_incomings(interface_id, ref_id, data ,created_at, posted_at) values
                 (#{@interface_id}, #{ref_id}, '#{msg}', '#{Time.new.utc}', '#{posted_at}')")
  end

  def notify_api
    uri = URI.parse("http://#{@api_serv_addr}/web_api/new_order_results")
    response = Net::HTTP.get_response(uri)
    @logger.info(JSON.parse(response.body))
  end

  def post_results(ref_id, message, url = 'http://127.0.0.1', store = true)
    begin
      uri = URI.parse("#{url}/orders/#{@interface_id}/interface_results")
      @logger.debug("Posting to #{url} time: #{Time.new.strftime("%M:%S:%L")}")
      response = Net::HTTP.post_form(uri, message: message)
      result = response.body
      posted_at = result && result.include?('success') ? Time.now.utc : nil
      @logger.debug("Posting response #{result} time: #{Time.new.strftime("%M:%S:%L")}")
    rescue
      @logger.error("Cannot post result #{$!}")
      posted_at = nil
    end
    store_order_result(ref_id, message, posted_at) if store
    posted_at
  end

  def post_old_results(url = 'http://127.0.0.1')

    rows = @dbh.query("select * from interface_incomings")
    rows.each_hash do |r|
      begin
        if r['posted_at']
          if Time.parse(r['created_at']) < (Time.now - 2592000) #30 days ago
            @dbh.query("delete from interface_incomings where id = #{r['id']}")
          end
        else
          @interface_id ||= r['interface_id']
          posted_at = post_results(r['ref_id'], r['data'], url , false)
          @dbh.query("update interface_incomings SET posted_at='#{posted_at}'") if posted_at
        end
      rescue
        @logger.error("Could not post old results #{$!}")
      end
    end
  end


  def response_hash(segs, message)

  end

end
