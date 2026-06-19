require "rails_helper"

RSpec.describe Integrations::JiraClient do
  describe "#all_issues" do
    it "uses valid JQL when the account is scoped to projects" do
      account = instance_double(
        IntegrationAccount,
        status: "connected",
        access_token: "token",
        metadata: {
          "base_url" => "https://example.atlassian.net",
          "email" => "demo@example.com",
          "projects" => ["JAR"]
        }
      )
      user = instance_double(User, email: "demo@example.com")
      allow(user).to receive_message_chain(:integration_accounts, :find_by).and_return(account)

      response = instance_double(
        Faraday::Response,
        success?: true,
        body: { "issues" => [], "isLast" => true }
      )
      connection = instance_double(Faraday::Connection)

      expect(connection).to receive(:post).with("/rest/api/3/search/jql") do |_path, &block|
        request = Struct.new(:headers, :body).new({}, nil)
        block.call(request)
        expect(request.body[:jql]).to eq(
          'project in ("JAR") AND (updated IS NOT EMPTY) ORDER BY updated DESC'
        )
        response
      end

      described_class.new(user: user, connection: connection).all_issues
    end
  end
end
