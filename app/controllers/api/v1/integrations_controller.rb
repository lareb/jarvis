module Api
  module V1
    class IntegrationsController < BaseController
      def jira_setup
        email = params.require(:email).presence
        api_token = params.require(:api_token).presence
        base_url = params.require(:base_url).presence

        raise ConfigurationError, "Email, API token, and base URL are required" unless email && api_token && base_url

        projects = Integrations::JiraVerifier.new(
          email: email,
          api_token: api_token,
          base_url: base_url
        ).verify

        account = current_user.integration_accounts.find_or_initialize_by(provider: "jira")
        account.update!(
          access_token: api_token,
          status: "connected",
          metadata: {
            email: email,
            base_url: base_url,
            projects: projects
          }
        )

        render json: {
          success: true,
          metadata: account.metadata
        }
      rescue Integrations::Error => e
        render json: { error: e.message, success: false }, status: :unprocessable_entity
      rescue ActionController::ParameterMissing => e
        render json: { error: "Missing required field: #{e.param}" }, status: :bad_request
      end

      def jira_status
        account = current_user.integration_accounts.find_by(provider: "jira")

        if account&.status == "connected"
          render json: {
            connected: true,
            email: account.metadata["email"],
            base_url: account.metadata["base_url"]
          }
        else
          render json: { connected: false }
        end
      end
    end
  end
end
