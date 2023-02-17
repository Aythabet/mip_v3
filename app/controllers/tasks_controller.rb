class TasksController < ApplicationController
  DEFAULT_USER_ID = 1
  DEFAULT_PORJECT_ID = 1

  def index
    @tasks = Task.all
  end

  def retrieve_tasks
    jira_ids = collect_all_task_jira_ids
    jira_ids.each do |jira_id|
      collect_and_save_task_information(jira_id)
    end

    redirect_to tasks_path
  end

  private

  def collect_all_task_jira_ids
    jira_ids = []
    start_at = 0
    response = call_jira_api("https://agenceinspire.atlassian.net/rest/api/3/search?jql=ORDER%20BY%20Created&startAt=#{start_at}&maxResults=50")

    if response.code == '200'
      total_issues_count = JSON.parse(response.body)['total']
      pp(total_issues_count)
      total_pages = 2 # (total_issues_count / 50.0).ceil

      (1..total_pages).each do |i|
        tasks = JSON.parse(response.body)
        jira_ids << tasks['issues'].map { |issue| issue['key'] }
        start_at += 50
        response = call_jira_api("https://agenceinspire.atlassian.net/rest/api/3/search?jql=&startAt=#{start_at}&maxResults=50")
      end
    end
    jira_ids.flatten
  end

  def collect_and_save_task_information(jira_id)
    url = "https://agenceinspire.atlassian.net/rest/api/3/issue/#{jira_id}"
    response = call_jira_api(url)
    return unless response.code == '200'

    json_task = JSON.parse(response.body)
    fields = json_task['fields']
    added_task = Task.find_or_create_by!(jira_id:) do |new_task|
      new_task.project_id = determine_the_project_id(json_task)
      new_task.assignee_id = determine_the_user_id(json_task)
      new_task.time_forecast = fields['timeoriginalestimate']
      new_task.status = fields['status']['name']
      new_task.created_at = fields['created']
      new_task.updated_at = fields['updated']
    end
    added_task.save
  end

  def determine_the_user_id(json_task)
    fields = json_task['fields']
    assignee_name = fields&.[]('assignee')&.[]('displayName')
    assignee = Assignee.find_or_create_by(name: assignee_name)
    assignee.id || DEFAULT_USER_ID
  end

  def determine_the_project_id(json_task)
    fields = json_task['fields']
    project_key = fields&.[]('project')&.[]('key')
    project = Project.find_or_create_by(jira_id: project_key)
    project.id || DEFAULT_PROJECT_ID
  end
end
