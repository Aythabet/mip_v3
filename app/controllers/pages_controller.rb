class PagesController < ApplicationController
  before_action :authenticate_user!

  def home
    basic_stats_projects_assignees_tasks
    active_tickets_partial
    @last_jira_update = JobsLog.where(title: ["TasksJob", "ImportTasksScheduler"]).order(created_at: :desc).first
  end

  private

  def other_tasks_by_assignee(assignee_id)
    other_tasks = Task.where(assignee_id: assignee_id)
    @other_tasks_count = other_tasks.count
  end

  def basic_stats_projects_assignees_tasks
    @total_number_of_projects = Project.count
    @total_number_of_tasks = Task.count
    @total_number_of_tasks_today = Task.where(created_at: Date.today.all_day).count
    @total_number_of_assignees = Assignee.count
  end

  def active_tickets_partial
    projects = Project
      .joins(:tasks)
      .where(tasks: { status: ["In Progress", "En cours", "en cours"] })
      .distinct
      .includes(:tasks)

    active_and_on_hold_tasks_count(projects)

    unique_tasks_count = Task.group(:status).count
    @unique_tasks_count = unique_tasks_count.sort_by { |status, count| count }.reverse
    @projects_with_active_tickets = projects
      .where(archived_status: false)
      .sort_by { |project| -1 * project.tasks.where(status: ["In Progress", "En cours", "en cours"]).count }
  end

  def active_and_on_hold_tasks_count(projects)
    @in_progress_tasks_count = 0
    @on_hold_tasks_count = 0
    projects.each do |project|
      @in_progress_tasks_count += project.tasks.where(status: ["In Progress", "En cours", "en cours"]).count
      @on_hold_tasks_count += project.tasks.where(status: ["En attente", "En Pause", "On Hold"]).count
    end
  end
end
