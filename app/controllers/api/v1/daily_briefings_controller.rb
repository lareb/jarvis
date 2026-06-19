module Api
  module V1
    class DailyBriefingsController < BaseController
      def show
        render json: DailyBriefingService.new(user: current_user).call
      end
    end
  end
end
