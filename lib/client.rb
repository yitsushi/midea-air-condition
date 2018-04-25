# frozen_string_literal: true

require 'digest/sha2'
require 'json'
require 'net/http'
require 'openssl'

module MideaAirCondition
  # Client for Midea AC server
  class Client
    SERVER_URL  = 'https://mapp.appsmb.com/v1'
    CLIENT_TYPE = 1                 # Android
    FORMAT      = 2                 # JSON
    LANGUAGE    = 'en_US'

    attr_accessor :debug

    def initialize(email, password, app_key:, app_id: 1017, src: 17)
      @app_id   = app_id
      @src      = src
      @email    = email
      @password = password
      @app_key  = app_key
      @debug    = false

      @security = Security.new(app_key: @app_key)

      @current = nil
    end

    def login
      login_id = user_login_id_get['loginId']

      encrypted_password = @security.encrypt_password(@password, login_id)
      @current = api_request(
        'user/login',
        loginAccount: @email,
        password: encrypted_password
      )
      @security.access_token = @current['accessToken']
    end

    def appliance_list
      response = api_request(
        'appliance/list/get',
        homegroupId: default_home['id']
      )
      response['list']
    end

    def appliance_transparent_send(appliance_id, data)
      response = api_request(
        'appliance/transparent/send',
        order: encode(@security.transcode(data).join(',')),
        funId: '0000',
        applianceId: appliance_id
      )

      response = decode(response['reply']).split(',').map { |p| p.to_i & 0xff }

      response
    end

    def new_packet_builder
      PacketBuilder.new(@security)
    end

    private

    def encode(data)
      @security.aes_encrypt(data, @security.data_key)
    end

    def decode(data)
      @security.aes_decrypt(data, @security.data_key)
    end

    def api_request(endpoint, **args)
      args = {
        appId: @app_id, format: FORMAT, clientType: CLIENT_TYPE,
        language: LANGUAGE, src: @src,
        stamp: Time.now.strftime('%Y%m%d%H%M%S')
      }.merge(args)

      args[:sessionId] = @current['sessionId'] unless @current.nil?

      path = "/#{SERVER_URL.split('/').last}/#{endpoint}"
      args[:sign] = @security.sign(path, args)

      result = send_api_request(URI("#{SERVER_URL}/#{endpoint}"), args)

      result['result']
    end

    def send_api_request(uri, args)
      Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
        request = Net::HTTP::Post.new(uri)
        request.set_form_data(args)

        result = JSON.parse(http.request(request).body)
        raise result['msg'] unless result['errorCode'] == '0'

        log(result['result'])
        result
      end
    end

    def user_login_id_get
      api_request('user/login/id/get', loginAccount: @email)
    end

    def default_home
      @default_home ||= api_home_list['list'].select do |h|
        h['isDefault'].to_i == 1
      end.first
    end

    def api_home_list
      api_request('homegroup/list/get')
    end

    def log(data)
      p data if @debug
    end
  end
end
