module Automation
  class TicketPrompt
    def initialize(ticket)
      @ticket = ticket
    end

    def to_s
      <<~PROMPT
        Implement the Jira ticket below in this repository.

        Ticket: #{ticket.external_id}
        Title: #{ticket.title}
        Description:
        #{ticket.body.presence || "(no description provided)"}

        Jira details:
        #{JSON.pretty_generate(ticket.metadata)}

        Requirements:
        - Inspect the repository and implement only the ticket's requested change.
        - Preserve unrelated user changes.
        - Add or update focused tests where appropriate.
        - Run the smallest relevant test suite and report the commands and results.
        - Do not create commits, switch branches, push, open pull requests, or update Jira.
        - Do not inspect credentials or secrets and do not use network access.
        - If the ticket is ambiguous or cannot be implemented safely, make no speculative changes and explain the blocker.
      PROMPT
    end

    private

    attr_reader :ticket
  end
end
