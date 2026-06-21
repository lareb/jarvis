class CreateJiraTickets < ActiveRecord::Migration[7.2]
  def change
    create_table :jira_tickets do |t|
      t.references :integration_account, null: false, foreign_key: true
      t.string :external_id, null: false
      t.string :title, null: false
      t.text :body
      t.jsonb :metadata, null: false, default: {}
      t.datetime :occurred_at
      t.datetime :last_synced_at, null: false

      t.timestamps
    end

    add_index :jira_tickets,
      [:integration_account_id, :external_id],
      unique: true,
      name: "index_jira_tickets_on_account_and_external_id"
    add_index :jira_tickets, :occurred_at
    add_index :jira_tickets, :last_synced_at
  end
end
