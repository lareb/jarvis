module Integrations
  class BaseClient
    def initialize(user:, provider:, connection: nil)
      @user = user
      @provider = provider
      @connection = connection
    end

    private

    attr_reader :user, :provider

    def account
      @account ||= user.integration_accounts.find_by(provider: provider)
    end

    def connected_account!
      return account if account&.status == "connected" && (account.access_token.present? || account.refresh_token.present?)

      raise ConfigurationError, "#{provider} is not connected"
    end

    def connection(base_url)
      @connection || Faraday.new(url: base_url) do |faraday|
        faraday.request :json
        faraday.response :json
        faraday.adapter Faraday.default_adapter
      end
    end

    def parse_time(value)
      Time.zone.parse(value.to_s) if value.present?
    rescue ArgumentError, TypeError
      nil
    end

    def ensure_success!(response)
      return response.body if response.success?

      update_account_status("expired") if response.status == 401
      update_account_status("error") if response.status == 403
      message = response.body.is_a?(Hash) ? response.body["message"] || response.body["error"] : response.body
      raise RequestError, "#{provider} request failed (#{response.status}): #{message.presence || 'unknown error'}"
    end

    def update_account_status(status)
      account&.update_column(:status, status)
    end
  end
end
