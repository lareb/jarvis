require "rails_helper"

RSpec.describe ApprovalPolicy do
  it "allows read actions" do
    expect(described_class.allowed?(:read_email)).to be(true)
  end

  it "blocks Phase 1 write actions" do
    expect { described_class.authorize!(:send_email) }
      .to raise_error(ApprovalPolicy::ReadOnlyViolation, /read-only/)
  end
end
