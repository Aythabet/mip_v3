module ApplicationHelper
  def my_helper_format_duration(seconds)
    ApplicationController.new.format_duration(seconds)
  end

  def my_helper_call_jira_api(url)
    ApplicationController.new.call_jira_api(url)
  end
end
