module Automation
  class CodexRunner
    def initialize(run, prompt:, runner: CommandRunner.new)
      @run = run
      @prompt = prompt
      @runner = runner
    end

    def call
      command = [
        ENV.fetch("CODEX_EXECUTABLE", "codex"),
        "exec",
        "--config", 'approval_policy="never"',
        "--ephemeral",
        "--json",
        "--sandbox", "workspace-write",
        "--cd", run.worktree_path,
        "-"
      ]
      log_command(command)
      result = runner.run!(
        *command,
        chdir: run.worktree_path,
        env: ExecutionEnvironment.codex,
        stdin_data: prompt,
        unsetenv_others: true
      )
      parse_output(result.stdout)
    end

    private

    attr_reader :run, :prompt, :runner

    def parse_output(output)
      events = output.each_line.filter_map do |line|
        JSON.parse(line)
      rescue JSON::ParserError
        nil
      end
      thread_id = events.find { |event| event["type"] == "thread.started" }&.dig("thread_id")
      messages = events.filter_map do |event|
        item = event["item"]
        item["text"] if event["type"] == "item.completed" && item&.dig("type") == "agent_message"
      end

      run.update!(
        codex_thread_id: thread_id,
        codex_output: messages.last.presence || output
      )
    end

    def log_command(command)
      safe_command = command.map { |part| part == "-" ? "<ticket prompt via stdin>" : part }
      run.update!(command_log: run.command_log + [ { command: safe_command, at: Time.current.iso8601 } ])
    end
  end
end
