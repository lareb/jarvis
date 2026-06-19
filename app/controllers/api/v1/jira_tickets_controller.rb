module Api
  module V1
    class JiraTicketsController < BaseController
      def index
        tickets = Integrations::JiraClient.new(user: current_user).all_issues
        account = current_user.integration_accounts.find_by!(provider: "jira")
        persisted_tickets = JiraTicketSyncService.new(integration_account: account).call(tickets)

        render json: {
          tickets: persisted_tickets.map(&:api_payload),
          total: persisted_tickets.length
        }
      rescue Integrations::Error, Faraday::Error, ActiveRecord::RecordNotFound => e
        Rails.logger.error(
          "Jira ticket fetch failed: #{e.class}: #{e.message}"
        )
        render json: { error: e.message }, status: :unprocessable_entity
      end
    end
  end
end
