class PublishJiraTicketJob < ApplicationJob
  queue_as :default

  def perform(run_id)
    Automation::TicketPublishService.new(TicketAutomationRun.find(run_id)).call
  end
end
