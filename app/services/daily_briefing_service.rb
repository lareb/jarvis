class DailyBriefingService
  def initialize(user:, context_collector: nil)
    @context_collector = context_collector || ContextCollector.new(user: user)
  end

  def call
    briefing = context_collector.daily_briefing

    briefing.merge(recommended_focus: recommendations(briefing))
  end

  private

  attr_reader :context_collector

  def recommendations(briefing)
    [
      ("Handle #{briefing[:important_emails].length} important email follow-up(s)" if briefing[:important_emails].any?),
      ("Review #{briefing[:jira_priorities].length} high-priority Jira issue(s)" if briefing[:jira_priorities].any?),
      ("Review #{briefing[:github_prs].length} pending GitHub pull request(s)" if briefing[:github_prs].any?),
      ("Prepare for #{briefing[:meetings].length} calendar commitment(s)" if briefing[:meetings].any?)
    ].compact
  end
end
