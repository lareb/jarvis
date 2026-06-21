require "rails_helper"

RSpec.describe Automation::Configuration do
  after do
    described_class.instance_variable_set(:@file_configuration, nil)
  end

  it "prefers the environment variable" do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with("JARVIS_AUTOMATION_REPOSITORY_PATH").and_return("/env/repository")

    expect(described_class.repository_path).to eq("/env/repository")
  end

  it "uses Rails configuration when the environment variable is absent" do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with("JARVIS_AUTOMATION_REPOSITORY_PATH").and_return(nil)
    described_class.instance_variable_set(
      :@file_configuration,
      { repository_path: "/configured/repository" }.with_indifferent_access
    )

    expect(described_class.repository_path).to eq("/configured/repository")
  end
end
