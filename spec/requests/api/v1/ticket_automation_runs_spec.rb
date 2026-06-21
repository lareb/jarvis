require "rails_helper"

RSpec.describe "Api::V1::TicketAutomationRuns" do
  include ActiveJob::TestHelper

  before do
    ActiveJob::Base.queue_adapter = :test
  end

  let(:user) do
    User.find_or_create_by!(email: "demo@example.com") { |record| record.name = "Demo User" }
  end
  let(:account) do
    user.integration_accounts.find_or_create_by!(provider: "jira") do |record|
      record.status = "connected"
      record.access_token = "token"
    end
  end
  let(:ticket) do
    account.jira_tickets.create!(
      external_id: "SUD-123",
      title: "Fix pagination",
      body: "Fix /api/v1/job_seekers",
      last_synced_at: Time.current
    )
  end

  around do |example|
    original = ENV["JARVIS_AUTOMATION_REPOSITORY_PATH"]
    ENV["JARVIS_AUTOMATION_REPOSITORY_PATH"] = Rails.root.to_s
    Automation::Configuration.instance_variable_set(:@file_configuration, nil)
    example.run
  ensure
    ENV["JARVIS_AUTOMATION_REPOSITORY_PATH"] = original
    Automation::Configuration.instance_variable_set(:@file_configuration, nil)
  end

  it "creates a persisted run that awaits approval" do
    post "/api/v1/jira_tickets/#{ticket.id}/automation_runs"

    expect(response).to have_http_status(:created)
    payload = JSON.parse(response.body).fetch("run")
    expect(payload["status"]).to eq("pending_approval")
    expect(payload["branch_name"]).to eq("SUD-123")
    expect(payload["repository_path"]).to eq(Rails.root.to_s)
  end

  it "queues implementation only after approval" do
    run = ticket.ticket_automation_runs.create!(
      branch_name: "SUD-123",
      repository_path: Rails.root.to_s
    )

    expect do
      post "/api/v1/ticket_automation_runs/#{run.id}/approve"
    end.to have_enqueued_job(ImplementJiraTicketJob).with(run.id)

    expect(response).to have_http_status(:accepted)
    expect(run.reload.approved_at).to be_present
  end

  it "queues publishing only when a run is ready for review" do
    run = ticket.ticket_automation_runs.create!(
      branch_name: "SUD-123",
      repository_path: Rails.root.to_s,
      status: "ready_for_review"
    )

    expect do
      post "/api/v1/ticket_automation_runs/#{run.id}/publish"
    end.to have_enqueued_job(PublishJiraTicketJob).with(run.id)

    expect(response).to have_http_status(:accepted)
  end
end
