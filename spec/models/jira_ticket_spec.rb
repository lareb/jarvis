require "rails_helper"

RSpec.describe JiraTicket, type: :model do
  it "requires a unique Jira issue key within an integration account" do
    user = User.create!(email: "jira-ticket-model@example.com", name: "Jira User")
    account = user.integration_accounts.create!(provider: "jira", status: "connected", access_token: "token")
    account.jira_tickets.create!(
      external_id: "JAR-42",
      title: "Existing ticket",
      last_synced_at: Time.current
    )

    duplicate = account.jira_tickets.new(
      external_id: "JAR-42",
      title: "Duplicate ticket",
      last_synced_at: Time.current
    )

    expect(duplicate).not_to be_valid
    expect(duplicate.errors[:external_id]).to be_present
  end
end
