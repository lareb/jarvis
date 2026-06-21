require "rails_helper"

RSpec.describe Automation::CodexRunner do
  it "passes the ticket prompt over stdin and persists structured Codex output" do
    run = instance_double(
      TicketAutomationRun,
      worktree_path: "/tmp/worktree",
      command_log: [],
      update!: true
    )
    runner = instance_double(Automation::CommandRunner)
    output = <<~JSONL
      {"type":"thread.started","thread_id":"thread-123"}
      {"type":"item.completed","item":{"type":"agent_message","text":"Implemented and tested."}}
    JSONL
    result = Automation::CommandRunner::Result.new(stdout: output, stderr: "", exit_status: 0)

    allow(runner).to receive(:run!).and_return(result)

    described_class.new(run, prompt: "ticket prompt", runner: runner).call

    expect(runner).to have_received(:run!).with(
      "codex", "exec",
      "--config", 'approval_policy="never"',
      "--ephemeral", "--json",
      "--sandbox", "workspace-write",
      "--cd", "/tmp/worktree", "-",
      chdir: "/tmp/worktree",
      env: hash_including("JARVIS_TICKET_PROMPT" => "1"),
      stdin_data: "ticket prompt",
      unsetenv_others: true
    )
    expect(run).to have_received(:update!).with(
      codex_thread_id: "thread-123",
      codex_output: "Implemented and tested."
    )
  end
end
