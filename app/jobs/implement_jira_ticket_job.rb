class ImplementJiraTicketJob < ApplicationJob
  queue_as :default

  def perform(run_id)
    Automation::TicketImplementationService.new(TicketAutomationRun.find(run_id)).call
  end
end
