require 'sidekiq-scheduler'

class CheckAssigneeOnVacationScheduler
  include Sidekiq::Worker

  def perform
    today = Date.today
    assignees = Assignee.all

    assignees.each do |assignee|
      active_vacations = Vacation.where(assignee_id: assignee.id)
      .where("start_date <= ? AND end_date >= ?", today, today)
      assignee.update(on_vacation: active_vacations.any?)
    end
  end
end
