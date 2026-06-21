require "rails_helper"

describe "POST /api/v1/integrations/jira/setup" do
  let(:user) { User.find_or_create_by!(email: "demo@example.com", name: "Demo User") }

  before do
    allow_any_instance_of(Api::V1::BaseController).to receive(:current_user).and_return(user)
  end

  context "with valid credentials" do
    it "creates integration account and returns projects" do
      verifier = instance_double(Integrations::JiraVerifier)
      allow(Integrations::JiraVerifier).to receive(:new).and_return(verifier)
      allow(verifier).to receive(:verify).and_return(["PROJ1", "PROJ2"])

      post "/api/v1/integrations/jira/setup", params: {
        email: "test@example.com",
        api_token: "valid-token",
        base_url: "https://test.atlassian.net"
      }

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to include(
        "success" => true,
        "metadata" => hash_including("email" => "test@example.com")
      )

      account = user.integration_accounts.find_by(provider: "jira")
      expect(account).to be_present
      expect(account.status).to eq("connected")
      expect(account.metadata["projects"]).to eq(["PROJ1", "PROJ2"])
    end
  end

  context "with invalid token" do
    it "returns error" do
      verifier = instance_double(Integrations::JiraVerifier)
      allow(Integrations::JiraVerifier).to receive(:new).and_return(verifier)
      allow(verifier).to receive(:verify).and_raise(Integrations::ConfigurationError, "Invalid email or API token")

      post "/api/v1/integrations/jira/setup", params: {
        email: "test@example.com",
        api_token: "invalid-token",
        base_url: "https://test.atlassian.net"
      }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)).to include("error" => /Invalid email or API token/)
    end
  end

  context "with invalid base URL" do
    it "returns error" do
      verifier = instance_double(Integrations::JiraVerifier)
      allow(Integrations::JiraVerifier).to receive(:new).and_return(verifier)
      allow(verifier).to receive(:verify).and_raise(Integrations::ConfigurationError, "Invalid Jira base URL")

      post "/api/v1/integrations/jira/setup", params: {
        email: "test@example.com",
        api_token: "valid-token",
        base_url: "https://invalid.atlassian.net"
      }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)).to include("error" => /Invalid Jira base URL/)
    end
  end

  context "with missing parameters" do
    it "returns error" do
      post "/api/v1/integrations/jira/setup", params: {
        email: "test@example.com"
      }

      expect(response).to have_http_status(:bad_request)
    end
  end
end

describe "GET /api/v1/integrations/jira/status" do
  let(:user) { User.find_or_create_by!(email: "demo@example.com", name: "Demo User") }

  before do
    allow_any_instance_of(Api::V1::BaseController).to receive(:current_user).and_return(user)
  end

  context "when connected" do
    it "returns connected status with metadata" do
      user.integration_accounts.create!(
        provider: "jira",
        status: "connected",
        access_token: "token",
        metadata: {
          email: "test@example.com",
          base_url: "https://test.atlassian.net"
        }
      )

      get "/api/v1/integrations/jira/status"

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to eq(
        "connected" => true,
        "email" => "test@example.com",
        "base_url" => "https://test.atlassian.net"
      )
    end
  end

  context "when not connected" do
    it "returns disconnected status" do
      get "/api/v1/integrations/jira/status"

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to eq("connected" => false)
    end
  end
end
