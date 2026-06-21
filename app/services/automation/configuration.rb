module Automation
  class Configuration
    class MissingSetting < StandardError; end

    class << self
      def repository_path
        fetch("JARVIS_AUTOMATION_REPOSITORY_PATH", :repository_path)
      end

      def base_branch
        fetch("JARVIS_AUTOMATION_BASE_BRANCH", :base_branch, default: "main")
      end

      def worktree_root
        fetch(
          "JARVIS_AUTOMATION_WORKTREE_ROOT",
          :worktree_root,
          default: Rails.root.join("tmp", "ticket_worktrees").to_s
        )
      end

      private

      def fetch(environment_key, file_key, default: nil)
        ENV[environment_key].presence ||
          file_configuration[file_key].presence ||
          default ||
          raise(MissingSetting, "#{environment_key} is not configured")
      end

      def file_configuration
        @file_configuration ||= Rails.application.config_for(:ticket_automation).with_indifferent_access
      rescue RuntimeError
        {}.with_indifferent_access
      end
    end
  end
end
