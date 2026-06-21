class JiraTicket < ApplicationRecord
  belongs_to :integration_account
  has_many :ticket_automation_runs, dependent: :destroy

  validates :external_id, presence: true, uniqueness: { scope: :integration_account_id }
  validates :title, presence: true
  validates :last_synced_at, presence: true

  def api_payload
    {
      id: id,
      source: "jira",
      external_id: external_id,
      title: title,
      body: body,
      metadata: metadata,
      occurred_at: occurred_at,
      latest_automation_run: ticket_automation_runs.recent_first.first&.api_payload
    }
  end
end
