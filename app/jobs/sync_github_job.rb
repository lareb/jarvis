class SyncGithubJob < ApplicationJob
  queue_as :integrations

  def perform(user_id)
    User.find(user_id)
    Integrations::GithubClient.new.pending_review_requests.count
  end
end
