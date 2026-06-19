require "rails_helper"

RSpec.describe User, type: :model do
  it "requires basic identity fields" do
    user = described_class.new

    expect(user).not_to be_valid
    expect(user.errors[:email]).to be_present
    expect(user.errors[:name]).to be_present
  end
end
