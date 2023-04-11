class AssigneesController < ApplicationController
  def index
    @assignees = Assignee
    .select('assignees.*, subquery.task_count')
    .from("(SELECT COUNT(*) AS task_count, assignee_id FROM tasks GROUP BY assignee_id) subquery")
    .joins('INNER JOIN assignees ON assignees.id = subquery.assignee_id')
    .order('subquery.task_count DESC, assignees.name')
    .page(params[:page])

    @assignees_count = Assignee.count
  end

  def retrieve_assignees
    url = 'https://agenceinspire.atlassian.net/rest/api/3/user/search?query=+&maxResults=1000'
    response = call_jira_api(url)
    return unless response.code == '200'

    json_assignee = JSON.parse(response.body)
    json_assignee.each do |assignee|
      assignee_name = assignee['displayName']
      assignee_email = assignee['emailAddress']
      find_or_create_assignee(assignee_name, assignee_email)
    end

    redirect_to assignees_path
  end

  def send_data_to_assignee
    assignee = Assignee.find(params[:id])
    ReportMailer.send_data_to_user(assignee).deliver_now
    redirect_to assignee_path, notice: 'Data sent to assignee'
    pp("#{assignee}==================================")
  end

  def show
    @assignee = Assignee.find(params[:id])
    @assignee_tasks = Task.where(assignee: @assignee).order(last_jira_update: :desc)

    # CR Today
    generate_cr(Date.today)

    assignee_unique_projects_list
    @tasks_by_time_status = tasks_by_time_status

    @assignee_tasks_paginated = Task.where(assignee: @assignee).order(last_jira_update: :desc).page params[:page]
    @total_time_estimation = 0
    @total_time_spent = 0

    @assignee_tasks.each do |task|
      @total_time_estimation += task.time_forecast || 0
      @total_time_spent += task.time_spent || 0
      @time_difference = @total_time_estimation - @total_time_spent

    end
  end

  def destroy_all
    Assignee.destroy_all("id != ?", 1)
    redirect_to assignees_path
  end

  private

  def find_or_create_assignee(assignee_name, assignee_email, admin: false)
    assignee_name = format_name(assignee_name)
    assignee_email = assignee_email.present? ? assignee_email : format_email(assignee_name)
    Assignee.create(email: assignee_email) do |user|
      user.name = assignee_name
      user.admin = admin
    end
  end

  def generate_cr(day)
    @assignee_todays_tasks = Task.where(assignee: @assignee)
    .where("DATE(last_jira_update) = ? OR DATE(created_at) = ?", day, day)
    .order(last_jira_update: :desc)

    @assignee_yesterday_tasks = Task.where(assignee: @assignee)
    .where("DATE(last_jira_update) = ? OR DATE(created_at) = ?", day - 1, day - 1)
    .order(last_jira_update: :desc)
  end

  def assignee_unique_projects_list
    # Load the project by ID
    @assignee = Assignee.find(params[:id])

    # Load all the unique assignees for the project's tasks
    @projects_jira_ids = @assignee.tasks.select(:project_id).distinct.joins(:project).pluck('projects.jira_id')

    @project_task_counts = {}
    @assignee.tasks.group(:project_id).count.each do |project_id, task_count|
      @project_task_counts[Project.find(project_id).jira_id] = task_count
    end

    @project_task_percentages = {}
    total_tasks = @assignee.tasks.count
    @project_task_counts.each do |project, task_count|
      @project_task_percentages[project] = (task_count.to_f / total_tasks * 100).round(2)
    end

    # Sort the unique assignees by the number of tasks in descending order
    @projects_jira_ids.sort_by! { |project| -@project_task_counts[project] }
  end

  def tasks_by_time_status
    assignee = Assignee.find(params[:id])
    total_tasks = assignee.tasks.count
    in_time_tasks = assignee.tasks.where("time_spent = time_forecast").count
    early_tasks = assignee.tasks.where("time_spent < time_forecast").count
    delayed_tasks = assignee.tasks.where("time_spent > time_forecast").count
    no_data_tasks = assignee.tasks.where("time_forecast IS NULL OR time_spent IS NULL").count

    in_time_percentage = (in_time_tasks.to_f / total_tasks.to_f * 100).round(2)
    early_percentage = (early_tasks.to_f / total_tasks.to_f * 100).round(2)
    delayed_percentage = (delayed_tasks.to_f / total_tasks.to_f * 100).round(2)
    no_data_percentage = (no_data_tasks.to_f / total_tasks.to_f * 100).round(2)

    { in_time: { count: in_time_tasks, percentage: in_time_percentage },
      early: { count: early_tasks, percentage: early_percentage },
      delayed: { count: delayed_tasks, percentage: delayed_percentage },
      no_data: {count: no_data_tasks, percentage: no_data_percentage }}
  end
end
