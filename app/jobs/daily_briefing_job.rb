class DailyBriefingJob < ApplicationJob
  queue_as :default

  def perform(user_id)
    User.find(user_id)
    DailyBriefingService.new.call
  end
end
