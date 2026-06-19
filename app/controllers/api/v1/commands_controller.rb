module Api
  module V1
    class CommandsController < BaseController
      def create
        command = current_user.commands.create!(raw_text: command_params.fetch(:command))
        response = CommandProcessor.new.process(command)

        render json: response.merge(id: command.id, status: command.status), status: :created
      rescue KeyError
        render json: { error: "command is required" }, status: :unprocessable_entity
      end

      def show
        command = current_user.commands.includes(:context_items, :ai_summary).find(params[:id])

        render json: {
          id: command.id,
          status: command.status,
          intent: command.intent,
          command: command.raw_text,
          response: command.response_payload,
          context: command.context_items.order(occurred_at: :desc).map { |item| context_payload(item) },
          ai_summary: ai_summary_payload(command.ai_summary),
          suggested_actions: command.ai_summary&.action_items || [],
          error_message: command.error_message
        }
      end

      private

      def command_params
        params.permit(:command)
      end

      def context_payload(item)
        {
          source: item.source,
          external_id: item.external_id,
          title: item.title,
          body: item.body,
          metadata: item.metadata,
          occurred_at: item.occurred_at
        }
      end

      def ai_summary_payload(ai_summary)
        return nil unless ai_summary

        {
          summary: ai_summary.summary,
          action_items: ai_summary.action_items,
          suggested_response: ai_summary.suggested_response,
          confidence_score: ai_summary.confidence_score.to_f
        }
      end
    end
  end
end
