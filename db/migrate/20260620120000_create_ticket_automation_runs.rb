class CreateTicketAutomationRuns < ActiveRecord::Migration[7.2]
  def change
    create_table :ticket_automation_runs do |t|
      t.references :jira_ticket, null: false, foreign_key: true
      t.string :status, null: false, default: "pending_approval"
      t.string :branch_name, null: false
      t.string :base_branch, null: false, default: "main"
      t.string :repository_path, null: false
      t.string :worktree_path
      t.string :codex_thread_id
      t.text :codex_output
      t.text :error_message
      t.jsonb :command_log, null: false, default: []
      t.string :commit_sha
      t.datetime :approved_at
      t.datetime :started_at
      t.datetime :completed_at
      t.datetime :published_at

      t.timestamps
    end

    add_index :ticket_automation_runs, :status
    add_index :ticket_automation_runs, :branch_name
  end
end
