require "rails_helper"

RSpec.describe IntentDetector do
  it "detects person update commands and extracts the person" do
    intent = described_class.new.detect("Any update from Anthony?")

    expect(intent.name).to eq("person_update")
    expect(intent.entities).to eq(person: "Anthony")
  end
end
