require "rails_helper"

RSpec.describe Command, type: :model do
  it "requires raw command text" do
    command = described_class.new(status: "pending")

    expect(command).not_to be_valid
    expect(command.errors[:raw_text]).to be_present
  end
end
