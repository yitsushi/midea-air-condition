require 'webrick'
require 'webrick/https'
require 'openssl'
require 'net/http'
require 'json'
require 'dotenv/load'

cert = OpenSSL::X509::Certificate.new File.read 'cert/test-cert.pem'
pkey = OpenSSL::PKey::RSA.new File.read 'cert/test-key.pem'

server = WEBrick::HTTPServer.new(
  :Port => 443,
  :SSLEnable => true,
  :SSLCertificate => cert,
  :SSLPrivateKey => pkey
)

ENV['accessToken'] = nil
APP_KEY = ENV.fetch('APP_KEY')

def getDataKey(accessToken, appKey)
  aesDecrypt(accessToken, (::Digest::MD5.new << appKey).to_s[0...16])
end

def aesDecrypt(data, key)
  aes = OpenSSL::Cipher.new('aes128')
  aes.decrypt
  aes.padding = 0
  aes.key = key

  data = [data].pack('H*')

  blocks = data.chars.each_slice(16).map(&:join)

  final = ""
  blocks.each do |b|
    aes.reset
    final += aes.update(b) + aes.final
  end

  pad = final[final.length - 1].ord

  final[0...(final.length - pad)]
end

def decode(accessToken, data)
  aesDecrypt(data, getDataKey(accessToken, APP_KEY))
end

def display_hex_request_map(data)
  values = data.split(',').map { |p| p.to_i & 0xff }

  puts ' --- REQUEST'
  puts ' = unkown (header start)'
  chunk = []
  20.times { chunk.push(values.shift) }
  puts hex_block_string(chunk)

  print ' = DeviceID [not]: '
  chunk = []
  8.times { chunk.push(values.shift) }
  puts chunk.map(&:chr).join('').unpack('q').first
  puts hex_block_string(chunk)

  puts ' = unknown'
  chunk = []
  12.times { chunk.push(values.shift) }
  puts hex_block_string(chunk)

  puts ' = unknown (maybe data)'
  puts hex_block_string(values)
  puts ' --- END OF REQUEST'
end

def display_hex_response_map(data)
  values = data.split(',').map { |p| p.to_i & 0xff }

  puts ' --- RESPONSE'
  puts ' = unkown (header start)'
  chunk = []
  20.times { chunk.push(values.shift) }
  puts hex_block_string(chunk)

  print ' = DeviceID: '
  chunk = []
  8.times { chunk.push(values.shift) }
  puts chunk.map(&:chr).join('').unpack('q').first
  puts hex_block_string(chunk)

  puts ' = unknown'
  chunk = []
  12.times { chunk.push(values.shift) }
  puts hex_block_string(chunk)

  puts ' = unknown (maybe data)'
  puts hex_block_string(values)
  puts ' --- END OF RESPONSE'
end

def hex_block_string(data, len: 8)
  data.map {|byte| sprintf("%02x", byte) }
      .each_slice(len)
      .map { |b| b.join(" ") }
      .join("\n")
end


SERVER_URL = 'https://mapp.appsmb.com'
def proxy_request(path, payload)
  payload = "" if payload.nil?
  payload = Hash[URI.decode_www_form(payload)]

  uri = URI("#{SERVER_URL}#{path}")
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = (uri.scheme == 'https')
  http.verify_mode = OpenSSL::SSL::VERIFY_NONE

  request = Net::HTTP::Post.new(uri)
  request.set_form_data(payload)
  response = http.request(request)

  jdata = JSON.parse(response.body)
  extra = nil
  if jdata.has_key? 'result'
    if response.body.match(/accessToken/)
      tmp = jdata['result']['accessToken']
      ENV['accessToken'] = tmp if tmp != ENV['accessToken']
    end
    if jdata['result'].has_key?('reply')
      extra = decode(ENV['accessToken'], jdata['result']['reply'])
    end
    if jdata['result'].has_key?('returnData')
      extra = decode(ENV['accessToken'], jdata['result']['returnData'])
    end
  end

  puts "<- Requested path: #{path}"
  puts "<- Payload: #{payload}"
  if payload.key?('order')
    decoded = decode(ENV['accessToken'], payload['order'])
    puts "<- Decoded: #{decoded}"
    display_hex_request_map decoded
  end
  if payload.key?('data')
    decoded = decode(ENV['accessToken'], payload['data'])
    puts "<- Decoded: #{decoded}"
    display_hex_request_map decoded
  end
  puts ' --- '
  puts "-> Response body: #{response.body}"
  puts "-> Decoded: #{extra}" unless extra.nil?
  display_hex_response_map extra unless extra.nil?

  puts '-------------------------'

  response.body
end

server.mount_proc '/' do |req, res|
  res.body = proxy_request(req.request_line.split(' ')[1], req.body)
end

trap 'INT' do server.shutdown end

server.start
