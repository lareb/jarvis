module Automation
  class TicketImplementationService
    def initialize(run, command_runner: CommandRunner.new)
      @run = run
      @command_runner = command_runner
    end

    def call
      run.update!(status: "running", started_at: Time.current, error_message: nil)
      TicketWorkspace.new(run, runner: command_runner).prepare!
      run_codex!
      run.update!(status: "ready_for_review", completed_at: Time.current)
    rescue StandardError => e
      run.update!(status: "failed", error_message: e.message, completed_at: Time.current)
      raise
    end

    private

    attr_reader :run, :command_runner

    def run_codex!
      prompt = TicketPrompt.new(run.jira_ticket).to_s
      CodexRunner.new(run, prompt: prompt, runner: command_runner).call
    end
  end
end
