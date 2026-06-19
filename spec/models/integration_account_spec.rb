require "rails_helper"

RSpec.describe IntegrationAccount, type: :model do
  it "accepts only known providers" do
    account = described_class.new(provider: "slack", status: "expired")

    expect(account).not_to be_valid
    expect(account.errors[:provider]).to be_present
  end
end
