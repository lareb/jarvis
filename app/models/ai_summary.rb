class AiSummary < ApplicationRecord
  belongs_to :command

  validates :summary, presence: true
  validates :action_items, presence: true
  validates :confidence_score, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 1 }
end
