class WebApi
  # Copyright Vidaguard 2013
  # Author: Claudio Mendoza
  require "net/http"
  require "uri"
  require "net/https"
  require 'json'

  BOUNDARY = "AaB03x"

  def self.get(url)
    uri = URI.parse(url)

# Shortcut
    response = Net::HTTP.get_response(uri)

# Will print response.body
    puts Net::HTTP.get_print(uri)
# Full
    http = Net::HTTP.new(uri.host, uri.port)
    response = http.request(Net::HTTP::Get.new(uri.request_uri))
  end

  def self.authorize

    uri = URI.parse("http://127.0.0.1:3000")

    http = Net::HTTP.new(uri.host, uri.port)
    request = Net::HTTP::Get.new(uri.request_uri)
    request.basic_auth("username", "password")
    response = http.request(request)
  end

  def self.view_orders(acc_tok, ord_typ, vendor_id, patient_id = nil)

    uri = URI('http://127.0.0.1:3000/orders')
    params = { access_token: acc_tok, order_type: ord_typ, vendor_id: vendor_id, patient_id: patient_id }
    uri.query = URI.encode_www_form(params)

    response = Net::HTTP.get_response(uri)
=begin ssl
    Net::HTTP.start(uri.host, uri.port,
                    :use_ssl => uri.scheme == 'https').start do |http|
      request = Net::HTTP::Get.new uri.request_uri

      response = http.request request # Net::HTTPResponse object
    end
=end
    puts response.body if response.is_a?(Net::HTTPSuccess)
    response
  end

  def self.assign_order(acc_tok, order_type, ancillary_id)
    uri = URI.parse("http://127.0.0.1:3000/orders")

# Shortcut
    data = {
        order: { type: order_type, name: 'ABO' },
        patient: { id: 2345, last_name: 'Jones', first_name: 'Paco', dob: '1982/12/22`' },
        insurance: { name: 'United Health', member_id: '234567' },
        visit: { room: '213', facility_id: 'location1' }
    }
    response = Net::HTTP.post_form(uri, data: data.to_json, access_token: acc_tok, ancillary_id: ancillary_id)

    result = JSON.parse(response.body)
=begin
# Full control
    http = Net::HTTP.new(uri.host, uri.port)

    request = Net::HTTP::Post.new(uri.request_uri)
    request.set_form_data({ "q" => "My query", "per_page" => "50" })

    response = http.request(request)
=end
  end


  def self.get_order(url)
    uri = URI.parse(url)

    http = Net::HTTP.new(uri.host, uri.port)
    request = Net::HTTP::Get.new(uri.request_uri)

    response = http.request(request)

    response.code # => 301
    response.body # => The body (HTML, XML, blob, whatever)
                  # Headers are lowercased
    response["cache-control"] # => public, max-age=2592000
  end


  def file_upload
    # Token used to terminate the file in the post body. Make sure it is not
    # present in the file you're uploading.


    uri = URI.parse("http://something.com/uploads")
    file = "/path/to/your/testfile.txt"

    post_body = []
    post_body << "--#{BOUNDARY}rn"
#    post_body << "Content-Disposition: form-data; name=" datafile "; filename=" #{File.basename(file)}"rn"
    post_body << "Content-Type: text/plainrn"
    post_body << "rn"
    post_body << File.read(file)
    post_body << "rn--#{BOUNDARY}--rn"

    http = Net::HTTP.new(uri.host, uri.port)
    request = Net::HTTP::Post.new(uri.request_uri)
    request.body = post_body.join
    request["Content-Type"] = "multipart/form-data, boundary=#{BOUNDARY}"

    http.request(request)
  end

  def self.ssl_always
    require 'always_verify_ssl_certificates'
    AlwaysVerifySSLCertificates.ca_file = "/path/path/path/cacert.pem"

    http= Net::HTTP.new('https://some.ssl.site', 443)
    http.use_ssl = true
    req = Net::HTTP::Get.new('/')
    response = http.request(req)
  end

  def self.ssl_request
    uri = URI.parse("https://secure.com/")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE

    request = Net::HTTP::Get.new(uri.request_uri)

    response = http.request(request)
    response.body
    response.status
    response["header-here"] # All headers are lowercase
  end

  def ssl_with_pem
    uri = URI.parse("https://secure.com/")
    pem = File.read("/path/to/my.pem")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.cert = OpenSSL::X509::Certificate.new(pem)
    http.key = OpenSSL::PKey::RSA.new(pem)
    http.verify_mode = OpenSSL::SSL::VERIFY_PEER

    request = Net::HTTP::Get.new(uri.request_uri)
  end

  def rest_methods
    http = Net::HTTP.new("api.restsite.com")

    request = Net::HTTP::Post.new("/users")
    request.set_form_data({ "users[login]" => "quentin" })
    response = http.request(request)
# Use nokogiri, hpricot, etc to parse response.body.

    request = Net::HTTP::Get.new("/users/1")
    response = http.request(request)
# As with POST, the data is in response.body.

    request = Net::HTTP::Put.new("/users/1")
    request.set_form_data({ "users[login]" => "changed" })
    response = http.request(request)

    request = Net::HTTP::Delete.new("/users/1")
    response = http.request(request)
  end

  def post_test

    @host = 'localhost'
    @port = '8099'

    @path = "/posts"

    @body ={
        "bbrequest" => "BBTest",
        "reqid" => "44",
        "data" => { "name" => "test" }
    }.to_json

    request = Net::HTTP::Post.new(@path, initheader = { 'Content-Type' => 'application/json' })
    request.body = @body
    response = Net::HTTP.new(@host, @port).start { |http| http.request(request) }
    puts "Response #{response.code} #{response.message}: #{response.body}"
  end

end