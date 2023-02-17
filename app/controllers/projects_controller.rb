class ProjectsController < ApplicationController
  def index
    @projects = Project.all
  end

  def retrieve_projects
    get_projects_data_with_pagination(0)
    get_projects_data_with_pagination(50)
    redirect_to projects_path
  end

  def show
    @project = Project.find(params[:id])
    @tasks = Task.where(project: @project)
  end

  private

  def get_projects_data_with_pagination(startat)
    url = "https://agenceinspire.atlassian.net/rest/api/3/project/search?startAt=#{startat}&maxResults=50&expand=lead"
    response = call_jira_api(url)
    return unless response.code == '200'

    json_projects = JSON.parse(response.body)
    collect_projects_information(json_projects)
  end

  def collect_projects_information(json_projects)
    i = 0
    json = json_projects['values']
    while i < json.length
      project_name = json[i]['name']
      project_jira_id = json[i]['key']
      project_lead = json[i]['lead']['displayName']
      find_or_create_project(project_name, project_jira_id, project_lead)
      i += 1
    end
  end

  def find_or_create_project(project_name, project_jira_id, project_lead)
    Project.find_or_create_by(name: project_name) do |project|
      project.jira_id = project_jira_id
      project.lead = project_lead
    end
  end
end
