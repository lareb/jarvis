require "rails_helper"

RSpec.describe Automation::TicketPrompt do
  it "includes the locally persisted Jira details and execution boundaries" do
    ticket = JiraTicket.new(
      external_id: "SUD-123",
      title: "Fix pagination",
      body: "Fix pagination in /api/v1/job_seekers",
      metadata: { priority: "High", status: "To Do" },
      last_synced_at: Time.current
    )

    prompt = described_class.new(ticket).to_s

    expect(prompt).to include("Ticket: SUD-123")
    expect(prompt).to include("Fix pagination in /api/v1/job_seekers")
    expect(prompt).to include('"priority": "High"')
    expect(prompt).to include("Do not create commits")
    expect(prompt).to include("do not use network access")
  end
end
