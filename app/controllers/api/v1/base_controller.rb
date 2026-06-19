module Api
  module V1
    class BaseController < ApplicationController
      private

      def current_user
        @current_user ||= User.find_or_create_by!(email: "demo@example.com") do |user|
          user.name = "Demo User"
        end
      end
    end
  end
end
