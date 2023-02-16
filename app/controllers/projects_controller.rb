class ProjectsController < ApplicationController
  def index
    @projects = Project.all
  end

  def retrieve_projects
    get_projects_data_with_pagination(0)
    get_projects_data_with_pagination(50)
    redirect_to projects_path
  end

  private

  def get_projects_data_with_pagination(startat)
    url = "https://agenceinspire.atlassian.net/rest/api/3/project/search?startAt=#{startat}&maxResults=50&expand=lead"
    response = call_jira_api(url)
    return unless response.code == '200'

    json_projects = JSON.parse(response.body)
    i = 0
    while i < json_projects['values'].length
      project_name = json_projects['values'][i]['name']
      project_jira_id = json_projects['values'][i]['key']
      find_or_create_project(project_name, project_jira_id)
      i += 1
    end
  end

  def find_or_create_project(project_name, project_jira_id)
    Project.find_or_create_by(name: project_name) do |project|
      project.jira_id = project_jira_id
    end
  end
end
