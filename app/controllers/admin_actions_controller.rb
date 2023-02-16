class AdminActionsController < ApplicationController
  def assignees
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

    redirect_to admin_actions_assignees_path
  end

  def find_or_create_assignee(assignee_name, assignee_email, admin=false)
    Assignee.find_or_create_by(name: assignee_name) do |user|
      user.email = assignee_email
      user.admin = admin
    end
  end
end
