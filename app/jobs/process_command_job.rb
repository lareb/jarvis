class ProcessCommandJob < ApplicationJob
  queue_as :default

  def perform(command_id)
    CommandProcessor.new.process(Command.find(command_id))
  end
end
