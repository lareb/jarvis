module Api
  module V1
    class TicketAutomationRunsController < BaseController
      before_action :set_run, only: %i[show approve publish]

      def create
        ticket = current_user.jira_tickets.find(params[:jira_ticket_id])
        run = ticket.ticket_automation_runs.create!(
          branch_name: ticket.external_id.upcase,
          base_branch: Automation::Configuration.base_branch,
          repository_path: Automation::Configuration.repository_path
        )

        render json: { run: run.api_payload }, status: :created
      rescue Automation::Configuration::MissingSetting => e
        render json: { error: e.message }, status: :unprocessable_entity
      end

      def show
        render json: { run: @run.api_payload }
      end

      def approve
        accepted = @run.with_lock do
          next false unless @run.status == "pending_approval"

          @run.update!(status: "queued", approved_at: Time.current)
          true
        end

        unless accepted
          return render json: { error: "run is not awaiting approval" }, status: :unprocessable_entity
        end

        ImplementJiraTicketJob.perform_later(@run.id)
        render json: { run: @run.reload.api_payload }, status: :accepted
      end

      def publish
        accepted = @run.with_lock do
          next false unless @run.status == "ready_for_review"

          @run.update!(status: "publishing")
          true
        end

        unless accepted
          return render json: { error: "run is not ready to publish" }, status: :unprocessable_entity
        end

        PublishJiraTicketJob.perform_later(@run.id)
        render json: { run: @run.reload.api_payload }, status: :accepted
      end

      private

      def set_run
        @run = TicketAutomationRun
          .joins(jira_ticket: :integration_account)
          .where(integration_accounts: { user_id: current_user.id })
          .find(params[:id])
      end
    end
  end
end
