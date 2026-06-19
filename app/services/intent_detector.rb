class IntentDetector
  Intent = Struct.new(:name, :entities, keyword_init: true)

  def detect(raw_text)
    text = raw_text.to_s.strip
    normalized = text.downcase

    if normalized.match?(/\Aany update from /)
      Intent.new(name: "person_update", entities: { person: extract_person(text) })
    elsif normalized.include?("important emails") || normalized.include?("today's emails")
      Intent.new(name: "important_emails", entities: { date: Date.current.iso8601 })
    elsif normalized.include?("focus on today") || normalized.include?("what should i focus")
      Intent.new(name: "daily_focus", entities: { date: Date.current.iso8601 })
    elsif normalized.include?("standup")
      Intent.new(name: "daily_standup", entities: { date: Date.current.iso8601 })
    else
      Intent.new(name: "unknown", entities: {})
    end
  end

  private

  def extract_person(text)
    text.sub(/\Aany update from\s+/i, "").delete_suffix("?").strip
  end
end
