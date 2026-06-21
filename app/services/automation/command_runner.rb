require "open3"

module Automation
  class CommandRunner
    Result = Data.define(:stdout, :stderr, :exit_status)

    class CommandFailed < StandardError
      attr_reader :result

      def initialize(command, result)
        @result = result
        super("#{command.first} exited with status #{result.exit_status}: #{result.stderr.presence || result.stdout}")
      end
    end

    def initialize(timeout: 30.minutes)
      @timeout = timeout
    end

    def run!(*command, chdir:, env: {}, stdin_data: nil, unsetenv_others: false)
      stdout, stderr, status = capture(
        *command,
        chdir: chdir,
        env: env,
        stdin_data: stdin_data,
        unsetenv_others: unsetenv_others
      )
      result = Result.new(stdout:, stderr:, exit_status: status.exitstatus)
      raise CommandFailed.new(command, result) unless status.success?

      result
    end

    private

    attr_reader :timeout

    def capture(*command, chdir:, env:, stdin_data:, unsetenv_others:)
      stdin, out, err, wait_thread = Open3.popen3(
        env,
        *command,
        chdir: chdir,
        unsetenv_others: unsetenv_others,
        pgroup: true
      )
      stdin.write(stdin_data) if stdin_data
      stdin.close
      stdout_thread = Thread.new { out.read }
      stderr_thread = Thread.new { err.read }

      unless wait_thread.join(timeout)
        terminate_process_group(wait_thread.pid)
        wait_thread.join
        raise CommandFailed.new(
          command,
          Result.new(stdout: stdout_thread.value, stderr: "command timed out", exit_status: 124)
        )
      end

      [ stdout_thread.value, stderr_thread.value, wait_thread.value ]
    ensure
      stdin&.close unless stdin&.closed?
      out&.close unless out&.closed?
      err&.close unless err&.closed?
    end

    def terminate_process_group(pid)
      Process.kill("TERM", -pid)
      sleep(0.2)
      Process.kill("KILL", -pid)
    rescue Errno::ESRCH
      nil
    end
  end
end
