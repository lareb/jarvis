require "rails_helper"

RSpec.describe "Api::V1::DailyBriefings" do
  before do
    item = {
      source: "gmail",
      external_id: "item-1",
      title: "Work item",
      body: "Current work context",
      metadata: {},
      occurred_at: Time.current
    }
    gmail = instance_double(Integrations::GmailClient, today_messages: [ item ])
    jira = instance_double(Integrations::JiraClient, high_priority_issues: [ item.merge(source: "jira") ])
    github = instance_double(Integrations::GithubClient, pending_review_requests: [ item.merge(source: "github") ])
    calendar = instance_double(Integrations::GoogleCalendarClient, today_events: [ item.merge(source: "google_calendar") ])

    collector = ContextCollector.new(
      gmail_client: gmail,
      jira_client: jira,
      github_client: github,
      calendar_client: calendar
    )
    allow(ContextCollector).to receive(:new).and_return(collector)
  end

  it "returns meetings, emails, Jira priorities, GitHub PRs, and focus recommendations" do
    get "/api/v1/daily_briefing"

    expect(response).to have_http_status(:ok)

    payload = JSON.parse(response.body)
    expect(payload["meetings"]).to be_present
    expect(payload["important_emails"]).to be_present
    expect(payload["jira_priorities"]).to be_present
    expect(payload["github_prs"]).to be_present
    expect(payload["recommended_focus"]).to include("Handle 1 important email follow-up(s)")
  end
end
