require 'base64'

module MideaAirCondition
  # Class to manage encryptions/decryptions/sign/etc
  class Security
    attr_accessor :access_token, :app_key

    def initialize(app_key:, access_token: '')
      @app_key      = app_key
      @access_token = access_token

      @crc8_854_table = Base64.decode64(
        'AF684mE/3YPCnH4go/0fQZ3DIX/8okAeXwHjvT5ggtwjfZ/BQhz+oOG/XQOA' \
        '3jxivuACXN+BYz18IsCeHUOh/0YY+qQneZvFhNo4ZuW7WQfbhWc5uuQGWBlH' \
        'pft4JsSaZTvZhwRauOan+RtFxph6JPimRBqZxyV7OmSG2FsF57mM0jBu7bNR' \
        'D04Q8qwvcZPNEU+t83AuzJLTjW8xsuwOUK/xE03OkHIsbTPRjwxSsO4ybI7Q' \
        'Uw3vsfCuTBKRzy1zypR2KKv1F0kIVrTqaTfVi1cJ67U2aIrUlcspd/SqSBbp' \
        't1ULiNY0ait1l8lKFPaodCrIlhVLqfe26ApU14lrNQ=='
      ).unpack('C*')
    end

    def sign(path, args)
      query = args.map { |k, v| "#{k}=#{v}" }.to_a.sort.join('&')
      content = "#{path}#{query}#{@app_key}"
      (::Digest::SHA2.new << content).to_s
    end

    def encrypt_password(password, login_id)
      pass = (::Digest::SHA2.new << password).to_s
      (::Digest::SHA2.new << "#{login_id}#{pass}#{@app_key}").to_s
    end

    def data_key
      aes_decrypt(
        @access_token,
        (::Digest::MD5.new << @app_key).to_s[0...16]
      )
    end

    def transcode(data)
      data.map do |d|
        (d >= 128 ? d - 256 : d)
      end
    end

    def crc8(data)
      crc_value = 0
      data.each do |m|
        k = crc_value ^ m
        k -= 256 if k > 256
        k += 256 if k < 0
        crc_value = CRC8_854_TABLE[k]
      end

      crc_value
    end

    def checksum(data)
      sum_value = data.inject(&:+)
      255 - sum_value % 256 + 1
    end

    def aes_decrypt(data, key)
      aes = OpenSSL::Cipher.new('aes128')
      aes.decrypt
      aes.padding = 0
      aes.key = key

      data = [data].pack('H*')

      blocks = data.chars.each_slice(16).map(&:join)

      final = ''
      blocks.each do |b|
        aes.reset
        final += aes.update(b) + aes.final
      end

      pad = final[final.length - 1].ord

      final[0...(final.length - pad)]
    end

    def aes_encrypt(data, key)
      aes = OpenSSL::Cipher.new('aes128')
      aes.encrypt
      aes.padding = 0
      aes.key = key

      blocks = data.chars.each_slice(16).map(&:join)
      if blocks.last.length < 16
        pad = 16 - blocks.last.length
        blocks[blocks.length - 1] = blocks.last + pad.chr * pad
      else
        pad = 16
        blocks << pad.chr * pad
      end

      final = ''
      blocks.each do |b|
        aes.reset
        final += aes.update(b) + aes.final
      end

      final.unpack('H*').first
    end
  end
end
