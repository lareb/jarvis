class JiraTicketSyncService
  UNIQUE_INDEX = "index_jira_tickets_on_account_and_external_id"

  def initialize(integration_account:)
    @integration_account = integration_account
  end

  def call(tickets)
    return [] if tickets.empty?

    synced_at = Time.current
    rows = tickets.map { |ticket| attributes_for(ticket, synced_at) }

    JiraTicket.upsert_all(
      rows,
      unique_by: UNIQUE_INDEX,
      update_only: %i[title body metadata occurred_at last_synced_at]
    )

    JiraTicket
      .where(integration_account: integration_account, external_id: rows.pluck(:external_id))
      .order(occurred_at: :desc)
  end

  private

  attr_reader :integration_account

  def attributes_for(ticket, synced_at)
    {
      integration_account_id: integration_account.id,
      external_id: ticket.fetch(:external_id),
      title: ticket.fetch(:title),
      body: ticket[:body],
      metadata: ticket[:metadata] || {},
      occurred_at: ticket[:occurred_at],
      last_synced_at: synced_at,
      created_at: synced_at,
      updated_at: synced_at
    }
  end
end
