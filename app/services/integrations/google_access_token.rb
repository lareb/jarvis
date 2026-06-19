module Integrations
  class GoogleAccessToken
    TOKEN_URL = "https://oauth2.googleapis.com/token"

    def initialize(account, connection: nil)
      @account = account
      @connection = connection
    end

    def call
      return account.access_token unless refresh_required?
      raise ConfigurationError, "#{account.provider} refresh token is missing" if account.refresh_token.blank?

      response = connection.post do |request|
        request.headers["Content-Type"] = "application/x-www-form-urlencoded"
        request.body = URI.encode_www_form(
          client_id: client_id,
          client_secret: client_secret,
          refresh_token: account.refresh_token,
          grant_type: "refresh_token"
        )
      end

      unless response.success?
        account.update_column(:status, "expired")
        raise RequestError, "Google token refresh failed (#{response.status})"
      end

      body = response.body
      account.update!(
        access_token: body.fetch("access_token"),
        expires_at: Time.current + body.fetch("expires_in", 3600).to_i.seconds,
        status: "connected"
      )
      account.access_token
    end

    private

    attr_reader :account

    def refresh_required?
      account.access_token.blank? ||
        (account.refresh_token.present? && account.expires_at.blank?) ||
        (account.expires_at.present? && account.expires_at <= 1.minute.from_now)
    end

    def client_id
      ENV.fetch("GOOGLE_CLIENT_ID")
    end

    def client_secret
      ENV.fetch("GOOGLE_CLIENT_SECRET")
    end

    def connection
      @connection ||= Faraday.new(url: TOKEN_URL) do |faraday|
        faraday.response :json
        faraday.adapter Faraday.default_adapter
      end
    end
  end
end
