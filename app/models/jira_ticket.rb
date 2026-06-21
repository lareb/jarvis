class JiraTicket < ApplicationRecord
  belongs_to :integration_account

  validates :external_id, presence: true, uniqueness: { scope: :integration_account_id }
  validates :title, presence: true
  validates :last_synced_at, presence: true

  def api_payload
    {
      source: "jira",
      external_id: external_id,
      title: title,
      body: body,
      metadata: metadata,
      occurred_at: occurred_at
    }
  end
end
