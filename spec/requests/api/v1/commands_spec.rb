require "rails_helper"

RSpec.describe "Api::V1::Commands" do
  before do
    gmail = instance_double(Integrations::GmailClient)
    jira = instance_double(Integrations::JiraClient)
    github = instance_double(Integrations::GithubClient)
    calendar = instance_double(Integrations::GoogleCalendarClient)

    allow(gmail).to receive(:latest_from).and_return([
      {
        source: "gmail",
        external_id: "message-1",
        title: "Update from Anthony",
        body: "Anthony sent a project update.",
        metadata: { action_items: [ "Review Anthony's update" ], important: true },
        occurred_at: 1.hour.ago
      }
    ])
    allow(jira).to receive(:issues_involving).and_return([
      {
        source: "jira",
        external_id: "JAR-1",
        title: "Project issue",
        body: "Anthony is involved in this issue.",
        metadata: {},
        occurred_at: 2.hours.ago
      }
    ])
    allow(github).to receive(:mentions_for).and_return([
      {
        source: "github",
        external_id: "123",
        title: "Pull request",
        body: "Anthony is involved in this pull request.",
        metadata: {},
        occurred_at: 3.hours.ago
      }
    ])

    collector = ContextCollector.new(
      gmail_client: gmail,
      jira_client: jira,
      github_client: github,
      calendar_client: calendar
    )
    allow(ContextCollector).to receive(:new).and_return(collector)
  end

  describe "POST /api/v1/commands" do
    it "processes a person update command and returns a structured response" do
      post "/api/v1/commands", params: { command: "Any update from Anthony?" }

      expect(response).to have_http_status(:created)

      payload = JSON.parse(response.body)
      expect(payload).to include(
        "intent" => "person_update",
        "status" => "completed"
      )
      expect(payload["summary"]).to include("Anthony")
      expect(payload["action_items"]).to include("Review Anthony's update")
      expect(payload["suggested_response"]).to include("Hi Anthony")

      command = Command.find(payload.fetch("id"))
      expect(command.context_items.pluck(:source)).to include("gmail", "jira", "github")
      expect(command.ai_summary).to be_present
    end
  end

  describe "GET /api/v1/commands/:id" do
    it "returns command status, context, and AI summary" do
      user = User.create!(email: "demo@example.com", name: "Demo User")
      command = user.commands.create!(raw_text: "Any update from Anthony?")
      CommandProcessor.new.process(command)

      get "/api/v1/commands/#{command.id}"

      expect(response).to have_http_status(:ok)

      payload = JSON.parse(response.body)
      expect(payload["status"]).to eq("completed")
      expect(payload["intent"]).to eq("person_update")
      expect(payload["context"].size).to eq(3)
      expect(payload.dig("ai_summary", "action_items")).to include("Review Anthony's update")
    end
  end
end
