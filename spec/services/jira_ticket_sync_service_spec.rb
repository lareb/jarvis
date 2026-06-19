require "rails_helper"

RSpec.describe JiraTicketSyncService do
  it "creates tickets and updates them on later syncs" do
    user = User.create!(email: "jira-sync@example.com", name: "Jira Sync User")
    account = user.integration_accounts.create!(provider: "jira", status: "connected", access_token: "token")
    service = described_class.new(integration_account: account)

    service.call([
      {
        source: "jira",
        external_id: "JAR-42",
        title: "Original title",
        body: "Original description",
        metadata: { status: "To Do" },
        occurred_at: 1.day.ago
      }
    ])

    service.call([
      {
        source: "jira",
        external_id: "JAR-42",
        title: "Updated title",
        body: "Updated description",
        metadata: { status: "In Progress" },
        occurred_at: Time.current
      }
    ])

    expect(account.jira_tickets.count).to eq(1)

    ticket = account.jira_tickets.find_by!(external_id: "JAR-42")
    expect(ticket.title).to eq("Updated title")
    expect(ticket.body).to eq("Updated description")
    expect(ticket.metadata["status"]).to eq("In Progress")
    expect(ticket.last_synced_at).to be_present
  end
end
