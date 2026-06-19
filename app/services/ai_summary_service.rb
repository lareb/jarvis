class AiSummaryService
  DEFAULT_MODEL = ENV.fetch("OPENAI_MODEL", "gpt-4o-mini")

  def initialize(openai_client: nil)
    @openai_client = openai_client
  end

  def summarize(command:, context_items:, entities: {})
    payload = openai_enabled? ? openai_summary(command, context_items, entities) : deterministic_summary(command, context_items, entities)

    command.create_ai_summary!(
      summary: payload.fetch(:summary),
      action_items: payload.fetch(:action_items),
      suggested_response: payload[:suggested_response],
      confidence_score: payload.fetch(:confidence_score, 0.75)
    )
  end

  private

  attr_reader :openai_client

  def openai_enabled?
    ENV["OPENAI_API_KEY"].present?
  end

  def client
    openai_client || OpenAI::Client.new(access_token: ENV.fetch("OPENAI_API_KEY"))
  end

  def openai_summary(command, context_items, entities)
    response = client.chat(
      parameters: {
        model: DEFAULT_MODEL,
        response_format: { type: "json_object" },
        messages: [
          { role: "system", content: system_prompt },
          { role: "user", content: user_prompt(command, context_items, entities) }
        ]
      }
    )

    JSON.parse(response.dig("choices", 0, "message", "content")).symbolize_keys
  rescue StandardError => e
    Rails.logger.warn("OpenAI summary failed, using deterministic summary: #{e.message}")
    deterministic_summary(command, context_items, entities)
  end

  def system_prompt
    <<~PROMPT
      You are Jarvis, a personal AI Chief of Staff for an Engineering Manager and Full Stack Developer.
      Summarize only the supplied context. Be concise, identify action items, and suggest drafts only.
      Phase 1 is read-only: never claim an action has been sent, created, closed, deleted, archived, or modified.
      Return JSON with summary, action_items, suggested_response, and confidence_score.
    PROMPT
  end

  def user_prompt(command, context_items, entities)
    {
      command: command.raw_text,
      intent: command.intent,
      entities: entities,
      context: context_items.map do |item|
        {
          source: item.source,
          title: item.title,
          body: item.body,
          metadata: item.metadata,
          occurred_at: item.occurred_at
        }
      end
    }.to_json
  end

  def deterministic_summary(command, context_items, entities)
    case command.intent
    when "person_update"
      person_update_summary(entities[:person], context_items)
    when "important_emails"
      important_email_summary(context_items)
    when "daily_focus"
      daily_focus_summary(context_items)
    when "daily_standup"
      daily_standup_summary(context_items)
    else
      {
        summary: "I could not confidently match that command to a Phase 1 Jarvis workflow.",
        action_items: [ "Rephrase using one of the Phase 1 commands" ],
        suggested_response: nil,
        confidence_score: 0.35
      }
    end
  end

  def person_update_summary(person, context_items)
    if context_items.empty?
      return {
        summary: "No connected source returned recent activity for #{person.presence || 'that contact'}.",
        action_items: [],
        suggested_response: nil,
        confidence_score: 0.2
      }
    end

    primary = context_items.max_by(&:occurred_at)
    action_items = context_items.flat_map { |item| item.metadata["action_items"] || [] }.uniq
    {
      summary: "#{person.presence || "This contact"} has recent activity: #{primary&.body || primary&.title || "no details found"}.",
      action_items: action_items,
      suggested_response: action_items.any? ? "Hi #{person}, thanks for the update. I’ll review this and follow up shortly." : nil,
      confidence_score: 0.82
    }
  end

  def important_email_summary(context_items)
    important = context_items.select { |item| item.metadata["important"] }
    {
      summary: "#{important.count} important email#{'s' unless important.one?} need attention today: #{important.map(&:title).join('; ')}.",
      action_items: important.flat_map { |item| item.metadata["action_items"] || [] }.uniq,
      suggested_response: nil,
      confidence_score: 0.78
    }
  end

  def daily_focus_summary(context_items)
    return empty_context_summary if context_items.empty?

    {
      summary: "Focus on the #{context_items.length} current item(s) returned by your connected work sources.",
      action_items: context_items.first(5).map { |item| "Review #{item.source}: #{item.title}" },
      suggested_response: nil,
      confidence_score: 0.76
    }
  end

  def daily_standup_summary(context_items)
    return empty_context_summary if context_items.empty?

    {
      summary: "Recent work context includes #{context_items.first(4).map(&:title).join('; ')}.",
      action_items: context_items.first(4).map { |item| "Mention #{item.title}" },
      suggested_response: nil,
      confidence_score: 0.74
    }
  end

  def empty_context_summary
    {
      summary: "No data was returned by the connected integrations for this command.",
      action_items: [],
      suggested_response: nil,
      confidence_score: 0.2
    }
  end
end
