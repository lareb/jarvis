module Integrations
  class JiraVerifier
    def initialize(email:, api_token:, base_url:)
      @email = email
      @api_token = api_token
      @base_url = base_url.delete_suffix("/")
    end

    def verify
      response = fetch_projects
      raise ConfigurationError, "Failed to connect: #{response_error(response)}" unless response.success?

      parse_projects(response.body)
    end

    private

    def fetch_projects
      Faraday.new(url: @base_url) do |faraday|
        faraday.request :json
        faraday.response :json
        faraday.adapter Faraday.default_adapter
      end.get("/rest/api/3/projects") do |request|
        request.headers["Authorization"] = "Basic #{Base64.strict_encode64("#{@email}:#{@api_token}")}"
        request.headers["Accept"] = "application/json"
      end
    end

    def response_error(response)
      case response.status
      when 401
        "Invalid email or API token"
      when 404
        "Invalid Jira base URL"
      else
        response.body.is_a?(Hash) ? response.body["message"] || "Connection failed" : "Connection failed"
      end
    end

    def parse_projects(body)
      return [] unless body.is_a?(Hash)

      values = body["values"]
      return [] unless values.is_a?(Array)

      values.map { |project| project["key"] }.compact
    end
  end
end
