module ApplicationHelper
  def my_helper_format_duration(seconds)
    ApplicationController.new.format_duration(seconds)
  end

  def my_helper_call_jira_api(url)
    ApplicationController.new.call_jira_api(url)
  end

  def my_helper_parse_duration(duration)
    case duration
    when /(\d+)w/
      $1.to_i * 7 * 24 * 60 * 60
    when /(\d+)d/
      $1.to_i * 24 * 60 * 60
    when /(\d+)h/
      $1.to_i * 60 * 60
    when /(\d+)m/
      $1.to_i * 60
    when /(\d+)s/
      $1.to_i
    else
      0
    end
  end
end
