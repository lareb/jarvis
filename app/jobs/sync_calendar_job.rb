class SyncCalendarJob < ApplicationJob
  queue_as :integrations

  def perform(user_id)
    User.find(user_id)
    Integrations::GoogleCalendarClient.new.today_events.count
  end
end
