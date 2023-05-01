require 'sidekiq-scheduler'

class CheckAssigneeOnVacationScheduler
  include Sidekiq::Worker

  def perform
    assignees = Assignee.all

    assignees.each do |assignee|
      active_vacations = Vacation.where("start_date <= ? AND ? < (start_date + interval '1 day' * duration)", Date.today, Date.today + 0.5)
      if active_vacations.any? { |vacation| vacation.assignee_id == assignee.id }
        assignee.update(on_vacation: true)
      else
        assignee.update(on_vacation: false)
      end
    end
  end
end
