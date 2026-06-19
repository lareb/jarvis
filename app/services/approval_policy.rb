class ApprovalPolicy
  BLOCKED_ACTIONS = %i[
    send_email
    delete_email
    archive_email
    create_jira_ticket
    close_jira_ticket
    modify_github_data
    modify_calendar_event
  ].freeze

  def self.allowed?(action)
    !BLOCKED_ACTIONS.include?(action.to_sym)
  end

  def self.authorize!(action)
    return true if allowed?(action)

    raise ReadOnlyViolation, "Phase 1 is read-only. #{action} is blocked."
  end

  class ReadOnlyViolation < StandardError; end
end
