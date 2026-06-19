require "rails_helper"

RSpec.describe AiSummary, type: :model do
  it "requires confidence between 0 and 1" do
    summary = described_class.new(summary: "Summary", action_items: [], confidence_score: 1.5)

    expect(summary).not_to be_valid
    expect(summary.errors[:confidence_score]).to be_present
  end
end
