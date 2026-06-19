class CommandProcessor
  def initialize(intent_detector: IntentDetector.new, context_collector: nil, ai_summary_service: AiSummaryService.new)
    @intent_detector = intent_detector
    @context_collector = context_collector
    @ai_summary_service = ai_summary_service
  end

  def process(command)
    detected = intent_detector.detect(command.raw_text)

    command.update!(
      intent: detected.name,
      status: "processing",
      started_at: Time.current,
      error_message: nil
    )

    collector = context_collector || ContextCollector.new(user: command.user)
    context_items = collector.collect(command: command, intent: detected.name, entities: detected.entities)
    ai_summary = ai_summary_service.summarize(command: command, context_items: context_items, entities: detected.entities)
    response = build_response(command, ai_summary)

    command.update!(status: "completed", response: response, completed_at: Time.current)
    response
  rescue StandardError => e
    command.update!(status: "failed", error_message: e.message, completed_at: Time.current)
    raise
  end

  private

  attr_reader :intent_detector, :context_collector, :ai_summary_service

  def build_response(command, ai_summary)
    {
      intent: command.intent,
      summary: ai_summary.summary,
      action_items: ai_summary.action_items,
      suggested_response: ai_summary.suggested_response,
      confidence_score: ai_summary.confidence_score.to_f
    }
  end
end
