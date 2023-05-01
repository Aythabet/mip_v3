require 'sidekiq-scheduler'

class AddVacationDaysScheduler
  include Sidekiq::Worker

  def perform
    assignees = Assignee.all
    if assignees.present?
      assignees.update_all("vacation_days_available = vacation_days_available + 2")
    end
  end
end
