class TestJob < ApplicationJob
  queue_as :default

  def perform
    pp("The job is working fine...")
    pp("------------------------------")
  end
end
