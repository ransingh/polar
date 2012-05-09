# encoding: UTF-8

require "zlib"
require "json"
require "faraday"
require "faraday_middleware"

module Polar
  class Client

    def initialize(api_key, secret_key, session_key)
      @api_key, @secret_key, @session_key = api_key, secret_key, session_key
    end

    def get_friends
      params = {
        :method => "friends.getFriends",
        :v => "1.0"
      }
      request(params, :post)
    end

    def get_info(uids, fields)
      params = {
        :method => "users.getInfo",
        :v => "1.0",
        :fields => fields * ",",
        :uids => uids * ","
      }
      request(params, :get)
    end

    def send_notification(receiver_ids, notification)
      params = {
        :method => "notifications.send",
        :v => "1.0",
        :to_ids => receiver_ids * ",",
        :notification => notification
      }
      request(params, :post)
    end

    def set_status(status)
      params = {
        :method => "status.set",
        :v => "1.0",
        :status => status
      }
      request(params, :post)
    end

    private

    def current_time_in_milliseconds
      "%.3f" % Time.now.to_f
    end

    def request(params, http_method)
      conn = Faraday.new(:url => RenrenAPI::BASE_URL) do |c|
        c.use Faraday::Request::UrlEncoded
        c.use Faraday::Response::Logger
        c.use Faraday::Adapter::NetHttp
      end

      conn.headers["Content-Type"] = ["application/x-www-form-urlencoded"];
      signature_calculator = SignatureCalculator.new(@secret_key)

      params[:api_key] = @api_key
      params[:call_id] = Time.now.to_i 
      params[:session_key] = @session_key
      params[:format] = "JSON"
      params[:sig] = signature_calculator.calculate(params)

      response = conn.post do |request|
        request.body = params.to_query
      end

      raise RenrenAPI::Error::HTTPError.new(response.status) if (400..599).include?(response.status)
      parsed_response = JSON.parse(response.body)
      raise RenrenAPI::Error::APIError.new(parsed_response) if renren_api_error?(parsed_response)
      parsed_response
    end

    def renren_api_error?(response_body)
      return false if response_body.class == Array 
      response_body.has_key?("error_code") && response_body.has_key?("error_msg")
    end

  end
end