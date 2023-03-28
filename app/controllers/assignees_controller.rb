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

  def show
    @assignee = Assignee.find(params[:id])
    @assignee_tasks = Task.where(assignee: @assignee).order(last_jira_update: :desc)

    # CR Today
    generate_cr(Date.today)

    @assignee_tasks_paginated = Task.where(assignee: @assignee).order(last_jira_update: :desc).page params[:page]
    @total_time_estimation = 0
    @total_time_spent = 0

    @assignee_tasks.each do |task|
      @total_time_estimation += task.time_forecast || 0
      @total_time_spent += task.time_spent || 0
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
end
