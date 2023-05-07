require 'sidekiq-scheduler'

class CheckAssigneeOnVacationScheduler
  include Sidekiq::Worker

  def perform
    job_start_time = Time.now
    today = Date.today
    assignees = Assignee.all

    assignees.each do |assignee|
      active_vacations = Vacation.where(assignee_id: assignee.id)
      .where("start_date <= ? AND end_date >= ?", today, today)
      assignee.update(on_vacation: active_vacations.any?)
    end
    job_end_time = Time.now
    JobsLog.create!(title: "CheckAssigneeOnVacationScheduler", execution_time: (job_end_time - job_start_time))
  end
end
