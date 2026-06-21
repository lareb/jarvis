require "rails_helper"

RSpec.describe TicketAutomationRun, type: :model do
  it "accepts a Jira issue key as its branch name" do
    run = described_class.new(
      jira_ticket: build_ticket,
      branch_name: "SUD-123",
      base_branch: "main",
      repository_path: "/tmp/repository"
    )

    expect(run).to be_valid
  end

  it "rejects a branch name that is not the Jira issue key format" do
    run = described_class.new(
      jira_ticket: build_ticket,
      branch_name: "feature/arbitrary;command",
      base_branch: "main",
      repository_path: "/tmp/repository"
    )

    expect(run).not_to be_valid
    expect(run.errors[:branch_name]).to be_present
  end

  def build_ticket
    user = User.create!(email: "automation-model@example.com", name: "Automation User")
    account = user.integration_accounts.create!(provider: "jira", status: "connected", access_token: "token")
    account.jira_tickets.build(
      external_id: "SUD-123",
      title: "Fix pagination",
      last_synced_at: Time.current
    )
  end
end
