module Automation
  class TicketPublishService
    def initialize(run, runner: CommandRunner.new)
      @run = run
      @runner = runner
    end

    def call
      unless %w[ready_for_review publishing].include?(run.status)
        raise ArgumentError, "run is not ready for review"
      end

      run.update!(status: "publishing", error_message: nil)
      ensure_changes!
      execute!("git", "add", "--all")
      execute!("git", "commit", "-m", commit_message)
      execute!("git", "push", "--set-upstream", "origin", run.branch_name)
      sha = execute!("git", "rev-parse", "HEAD").stdout.strip
      run.update!(status: "completed", commit_sha: sha, published_at: Time.current)
    rescue StandardError => e
      run.update!(status: "failed", error_message: e.message, completed_at: Time.current)
      raise
    end

    private

    attr_reader :run, :runner

    def ensure_changes!
      status = execute!("git", "status", "--porcelain").stdout
      raise ArgumentError, "Codex produced no changes to publish" if status.blank?
    end

    def execute!(*command)
      safe_command = command.first == "git" ? [ "git", "-c", "core.hooksPath=/dev/null", *command.drop(1) ] : command
      run.update!(command_log: run.command_log + [ { command: safe_command, at: Time.current.iso8601 } ])
      runner.run!(
        *safe_command,
        chdir: run.worktree_path,
        env: ExecutionEnvironment.git,
        unsetenv_others: true
      )
    end

    def commit_message
      "[#{run.jira_ticket.external_id}] #{run.jira_ticket.title}".truncate(200)
    end
  end
end
