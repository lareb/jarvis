require "rails_helper"

RSpec.describe "Api::V1::JiraTickets" do
  it "returns all Jira tickets" do
    user = User.find_or_create_by!(email: "demo@example.com") { |record| record.name = "Demo User" }
    user.integration_accounts.find_or_create_by!(provider: "jira") do |account|
      account.status = "connected"
      account.access_token = "token"
    end
    tickets = [
      {
        source: "jira",
        external_id: "JAR-42",
        title: "Ship the Jira workspace",
        body: "Finish the focused Jira experience.",
        metadata: {
          priority: "High",
          status: "In Progress",
          assignee: "Demo User",
          url: "https://example.atlassian.net/browse/JAR-42"
        },
        occurred_at: Time.current
      }
    ]
    jira = instance_double(Integrations::JiraClient, all_issues: tickets)
    allow(Integrations::JiraClient).to receive(:new).and_return(jira)

    get "/api/v1/jira_tickets"

    expect(response).to have_http_status(:ok)

    payload = JSON.parse(response.body)
    expect(payload["total"]).to eq(1)
    expect(payload.dig("tickets", 0, "external_id")).to eq("JAR-42")
    expect(user.integration_accounts.find_by!(provider: "jira").jira_tickets.find_by!(external_id: "JAR-42").title)
      .to eq("Ship the Jira workspace")
  end

  it "returns a useful error when Jira is unavailable" do
    jira = instance_double(Integrations::JiraClient)
    allow(jira).to receive(:all_issues).and_raise(Integrations::ConfigurationError, "jira is not connected")
    allow(Integrations::JiraClient).to receive(:new).and_return(jira)

    get "/api/v1/jira_tickets"

    expect(response).to have_http_status(:unprocessable_entity)
    expect(JSON.parse(response.body)["error"]).to eq("jira is not connected")
  end
end
