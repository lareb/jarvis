class CreateIntegrationAccounts < ActiveRecord::Migration[7.2]
  def change
    create_table :integration_accounts do |t|
      t.references :user, null: false, foreign_key: true
      t.string :provider, null: false
      t.text :access_token
      t.text :refresh_token
      t.datetime :expires_at
      t.jsonb :metadata, null: false, default: {}
      t.string :status, null: false, default: "mock"

      t.timestamps
    end

    add_index :integration_accounts, [:user_id, :provider], unique: true
    add_check_constraint :integration_accounts, "provider IN ('gmail', 'jira', 'github', 'google_calendar')", name: "integration_accounts_provider_check"
  end
end
