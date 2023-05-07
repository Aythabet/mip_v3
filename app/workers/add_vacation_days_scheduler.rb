require 'sidekiq-scheduler'

class AddVacationDaysScheduler
  include Sidekiq::Worker

  def perform
    job_start_time = Time.now

    assignees = Assignee.all
    if assignees.present?
      assignees.update_all("vacation_days_available = vacation_days_available + 2")
    end
  end
  job_end_time = Time.now
  JobsLog.create!(title: "AddVacationDaysScheduler", execution_time: (job_end_time - job_start_time))
end
