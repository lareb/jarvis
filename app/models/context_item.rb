class ContextItem < ApplicationRecord
  SOURCES = %w[gmail jira github google_calendar].freeze

  belongs_to :command

  validates :source, presence: true, inclusion: { in: SOURCES }
  validates :title, presence: true
end
