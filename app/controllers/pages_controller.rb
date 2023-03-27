class PagesController < ApplicationController
  before_action :authenticate_user!

  def home
    basic_stats_projects_assignees_tasks
    tickets_done_in_progress_waiting_count
    top_active_assignee_last_three_days
    active_tickets_partial
  end

  private

  def basic_stats_projects_assignees_tasks
    @total_number_of_projects = Project.count
    @total_number_of_tasks = Task.count
    @total_number_of_assignees = Assignee.count
  end

  def tickets_done_in_progress_waiting_count
    @number_of_tickets_in_progress_today = Task.where("LOWER(status) IN (?) AND last_jira_update AT TIME ZONE 'UTC' >= ?",
                                                      'in progress',
                                                      Time.current.beginning_of_day.utc).count
    @number_of_tickets_done_today = Task.where("LOWER(status) IN (?, ?, ?) AND last_jira_update AT TIME ZONE 'UTC' >= ?",
                                               'done', 'validé', 'valide',
                                               Time.current.beginning_of_day.utc).count
    @number_of_tickets_waiting_today = Task.where("LOWER(status) IN (?) AND last_jira_update AT TIME ZONE 'UTC' >= ?",
                                                  'en attente',
                                                  Time.current.beginning_of_day.utc).count
    @number_of_tickets_in_progress_yesterday = Task.where("LOWER(status) IN (?) AND last_jira_update AT TIME ZONE 'UTC' >= ?",
                                                          'in progress',
                                                          (Time.current - 1.days).beginning_of_day.utc).count
    @number_of_tickets_done_yesterday = Task.where("LOWER(status) IN (?, ?, ?) AND last_jira_update AT TIME ZONE 'UTC' >= ?",
                                                   'done', 'validé', 'valide',
                                                   (Time.current - 1.days).beginning_of_day.utc).count
    @number_of_tickets_waiting_yesterday = Task.where("LOWER(status) IN (?) AND last_jira_update AT TIME ZONE 'UTC' >= ?",
                                                      'en attente',
                                                      (Time.current - 1.days).beginning_of_day.utc).count
  end

  def top_active_assignee_last_three_days
    @assignees_and_tickets_count = []
    assignees = Assignee.all
    assignees.each do |assignee|
      ticket_count = Task.where(assignee_id: assignee.id, last_jira_update: (Time.current.beginning_of_day.utc)..Time.current).count
      @assignees_and_tickets_count << { name: assignee.name, id: assignee.id ,ticket_count: } if ticket_count.positive?
    end
  end

  def active_tickets_partial
    projects = Project
    .joins(:tasks)
    .where(tasks: { status: 'In Progress' })
    .distinct
    .includes(:tasks)

    @projects_with_active_tickets = projects.sort_by{ |project| -1 * project.tasks.where(status: 'In Progress').count }
  end
end
