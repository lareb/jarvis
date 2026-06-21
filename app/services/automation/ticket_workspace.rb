require "pathname"

module Automation
  class TicketWorkspace
    REPOSITORY_MARKER = ".git"

    def initialize(run, runner: CommandRunner.new)
      @run = run
      @runner = runner
    end

    def prepare!
      validate_repository!
      ensure_branch_available!
      run_git!("fetch", "origin", run.base_branch)

      FileUtils.mkdir_p(worktree_root)
      run_git!("worktree", "add", "-b", run.branch_name, worktree_path.to_s, "origin/#{run.base_branch}")
      run.update!(worktree_path: worktree_path.to_s)
    end

    private

    attr_reader :run, :runner

    def repository_path
      @repository_path ||= Pathname.new(run.repository_path).expand_path.cleanpath
    end

    def worktree_root
      @worktree_root ||= Pathname.new(Configuration.worktree_root).expand_path.cleanpath
    end

    def worktree_path
      @worktree_path ||= worktree_root.join("#{run.branch_name.downcase}-#{run.id}")
    end

    def validate_repository!
      raise ArgumentError, "repository does not exist" unless repository_path.directory?
      raise ArgumentError, "repository_path must point to a Git repository" unless repository_path.join(REPOSITORY_MARKER).exist?
      raise ArgumentError, "worktree path already exists" if worktree_path.exist?
    end

    def ensure_branch_available!
      result = run_git!("branch", "--list", run.branch_name)
      raise ArgumentError, "branch #{run.branch_name} already exists locally" if result.stdout.present?

      remote = run_git!("ls-remote", "--heads", "origin", run.branch_name)
      raise ArgumentError, "branch #{run.branch_name} already exists on origin" if remote.stdout.present?
    end

    def run_git!(*arguments)
      command = [ "git", "-c", "core.hooksPath=/dev/null", *arguments ]
      run.update!(command_log: run.command_log + [ { command: command, at: Time.current.iso8601 } ])
      runner.run!(
        *command,
        chdir: repository_path,
        env: ExecutionEnvironment.git,
        unsetenv_others: true
      )
    end
  end
end
