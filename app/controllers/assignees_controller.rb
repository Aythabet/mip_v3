class AssigneesController < ApplicationController
  def index
    @assignees = Assignee.all
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
    @tasks = Task.where(assignee: @assignee)
    @total_time_estimation = 0
    @total_time_spent = 0

    @tasks.each do |task|
      @total_time_estimation += task.time_forecast.to_i || 0
      @total_time_spent += task.time_spent.to_i || 0
    end
  end

  private

  def find_or_create_assignee(assignee_name, assignee_email, admin: false)
    assignee = Assignee.find_or_create_by(name: assignee_name) do |user|
      user.email = assignee_email
      user.admin = admin
    end
    assignee.save
  end
end
