require "rails_helper"

RSpec.describe ContextItem, type: :model do
  it "requires a known source and title" do
    item = described_class.new(source: "unknown")

    expect(item).not_to be_valid
    expect(item.errors[:source]).to be_present
    expect(item.errors[:title]).to be_present
  end
end
