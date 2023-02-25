class PagesController < ApplicationController
  skip_before_action :authenticate_user!, only: [:home]

  def home
    basic_stats_projects_assignees_tasks
    tickets_done_in_progress_waiting_count
    top_active_assignee_last_three_days
  end

  private

  def basic_stats_projects_assignees_tasks
    @total_number_of_projects = Project.count
    @total_number_of_tasks = Task.count
    @total_number_of_assignees = Assignee.count
  end

  def tickets_done_in_progress_waiting_count
    @number_of_tickets_in_progress = Task.where("LOWER(status) IN (?) AND updated_at AT TIME ZONE 'UTC' >= ?",
                                                'in progress',
                                                (Time.current - 3.days).beginning_of_day.utc).count
    @number_of_tickets_done_last_three_days = Task.where("LOWER(status) IN (?, ?, ?) AND updated_at AT TIME ZONE 'UTC' >= ?",
                                                         'done', 'validé', 'valide',
                                                         (Time.current - 3.days).beginning_of_day.utc).count
    @number_of_tickets_waiting_last_three_days = Task.where("LOWER(status) IN (?) AND updated_at AT TIME ZONE 'UTC' >= ?",
                                                            'en attente',
                                                            (Time.current - 3.days).beginning_of_day.utc).count
  end

  def top_active_assignee_last_three_days
    @assignees_and_tickets_count = []
    assignees = Assignee.all
    assignees.each do |assignee|
      ticket_count = Task.where(assignee_id: assignee.id, updated_at: (Time.current - 1.days)..Time.current).count
      @assignees_and_tickets_count << { name: assignee.name, id: assignee.id ,ticket_count: } if ticket_count.positive?
    end
  end
end
