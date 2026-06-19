class Command < ApplicationRecord
  INTENTS = %w[person_update important_emails daily_focus daily_standup unknown].freeze
  STATUSES = %w[pending processing completed failed].freeze

  belongs_to :user
  has_many :context_items, dependent: :destroy
  has_one :ai_summary, dependent: :destroy

  validates :raw_text, presence: true
  validates :intent, inclusion: { in: INTENTS }, allow_nil: true
  validates :status, presence: true, inclusion: { in: STATUSES }

  def response_payload
    return response if response.present?

    {
      intent: intent,
      summary: ai_summary&.summary,
      action_items: ai_summary&.action_items || [],
      suggested_response: ai_summary&.suggested_response,
      confidence_score: ai_summary&.confidence_score&.to_f
    }
  end
end
