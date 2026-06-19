class IntegrationAccount < ApplicationRecord
  PROVIDERS = %w[gmail jira github google_calendar].freeze
  STATUSES = %w[connected expired revoked error].freeze

  belongs_to :user

  encrypts :access_token
  encrypts :refresh_token

  validates :provider, presence: true, inclusion: { in: PROVIDERS }
  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :provider, uniqueness: { scope: :user_id }
end
