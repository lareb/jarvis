class ContextCollector
  def initialize(
    user: nil,
    gmail_client: nil,
    jira_client: nil,
    github_client: nil,
    calendar_client: nil
  )
    @gmail_client = gmail_client || Integrations::GmailClient.new(user: user)
    @jira_client = jira_client || Integrations::JiraClient.new(user: user)
    @github_client = github_client || Integrations::GithubClient.new(user: user)
    @calendar_client = calendar_client || Integrations::GoogleCalendarClient.new(user: user)
  end

  def collect(command:, intent:, entities:)
    items = case intent
    when "person_update"
      collect_person_update(entities.fetch(:person, nil))
    when "important_emails"
      collect_important_emails
    when "daily_focus"
      collect_daily_focus
    when "daily_standup"
      collect_daily_standup
    else
      []
    end

    items.map { |item| persist_context_item(command, item) }
  end

  def daily_briefing
    {
      meetings: safe_fetch("google_calendar") { calendar_client.today_events },
      important_emails: safe_fetch("gmail") { gmail_client.today_messages },
      jira_priorities: safe_fetch("jira") { jira_client.high_priority_issues },
      github_prs: safe_fetch("github") { github_client.pending_review_requests }
    }
  end

  private

  attr_reader :gmail_client, :jira_client, :github_client, :calendar_client

  def collect_person_update(person)
    [
      safe_fetch("gmail") { gmail_client.latest_from(person) },
      safe_fetch("jira") { jira_client.issues_involving(person) },
      safe_fetch("github") { github_client.mentions_for(person) }
    ].flatten
  end

  def collect_important_emails
    safe_fetch("gmail") { gmail_client.today_messages }
  end

  def collect_daily_focus
    [
      safe_fetch("google_calendar") { calendar_client.today_events },
      safe_fetch("jira") { jira_client.high_priority_issues },
      safe_fetch("github") { github_client.pending_review_requests },
      safe_fetch("gmail") { gmail_client.today_messages }
    ].flatten
  end

  def collect_daily_standup
    [
      safe_fetch("jira") { jira_client.recent_activity },
      safe_fetch("github") { github_client.recent_work },
      safe_fetch("gmail") { gmail_client.today_messages }
    ].flatten
  end

  def persist_context_item(command, item)
    command.context_items.create!(
      source: item.fetch(:source),
      external_id: item[:external_id],
      title: item.fetch(:title),
      body: item[:body],
      metadata: item[:metadata] || {},
      occurred_at: item[:occurred_at]
    )
  end

  def safe_fetch(provider)
    yield
  rescue Integrations::Error, Faraday::Error => e
    Rails.logger.warn("#{provider} context unavailable: #{e.message}")
    []
  end
end
