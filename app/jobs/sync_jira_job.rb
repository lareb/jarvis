class SyncJiraJob < ApplicationJob
  queue_as :integrations

  def perform(user_id)
    User.find(user_id)
    Integrations::JiraClient.new.high_priority_issues.count
  end
end
