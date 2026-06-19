class SyncGmailJob < ApplicationJob
  queue_as :integrations

  def perform(user_id)
    User.find(user_id)
    Integrations::GmailClient.new.today_messages.count
  end
end
