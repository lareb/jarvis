class RemoveMockIntegrationStatus < ActiveRecord::Migration[7.2]
  def up
    execute "UPDATE integration_accounts SET status = 'expired' WHERE status = 'mock'"
    change_column_default :integration_accounts, :status, from: "mock", to: "expired"
  end

  def down
    change_column_default :integration_accounts, :status, from: "expired", to: "mock"
  end
end
