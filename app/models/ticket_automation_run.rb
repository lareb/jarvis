class TicketAutomationRun < ApplicationRecord
  STATUSES = %w[
    pending_approval
    queued
    running
    ready_for_review
    publishing
    completed
    failed
  ].freeze

  belongs_to :jira_ticket

  validates :status, inclusion: { in: STATUSES }
  validates :branch_name, :base_branch, :repository_path, presence: true
  validates :branch_name, format: {
    with: /\A[A-Z][A-Z0-9]+-\d+\z/,
    message: "must be a Jira issue key such as SUD-123"
  }
  validates :base_branch, format: {
    with: /\A[a-zA-Z0-9][a-zA-Z0-9._\/-]*\z/,
    message: "is not a valid Git branch name"
  }

  scope :recent_first, -> { order(created_at: :desc) }

  def api_payload
    {
      id: id,
      jira_ticket_id: jira_ticket_id,
      ticket_key: jira_ticket.external_id,
      status: status,
      branch_name: branch_name,
      base_branch: base_branch,
      repository_path: repository_path,
      worktree_path: worktree_path,
      codex_thread_id: codex_thread_id,
      codex_output: codex_output,
      error_message: error_message,
      command_log: command_log,
      commit_sha: commit_sha,
      approved_at: approved_at,
      started_at: started_at,
      completed_at: completed_at,
      published_at: published_at,
      created_at: created_at,
      updated_at: updated_at
    }
  end
end
