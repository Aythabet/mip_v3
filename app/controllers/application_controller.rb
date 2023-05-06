class ApplicationController < ActionController::Base
  include ActionView::Helpers::NumberHelper
  before_action :add_initial_breadcrumbs
  before_action :authenticate_user!

  def check_admin
    unless current_user.admin?
      flash[:alert] = "You don't have permission to access this page. #{current_user.admin?}"
      redirect_to root_path
    end
  end

  def format_duration(seconds)
    if seconds.nil?
      return "No data"
    elsif seconds == 0
      return "0s"
    elsif seconds < 0
      return "-#{format_duration(-seconds)}"
    end

    minutes = seconds / 60.0
    if minutes < 60
      return "#{minutes.round(1)}min"
    end

    hours = minutes / 60.0
    if hours < 8
      return "#{hours.round(1)}h"
    end

    days = (hours / 8).floor
    hours %= 8
    hours = hours.round(1)

    duration = []
    duration << "#{days} day#{'s' if days > 1}" if days.positive?
    duration << "#{hours} hour#{'s' if hours > 1}" if hours.positive?
    duration.join(' and ')
  end

  def call_jira_api(url)
    uri = URI.parse(url)
    headers = {
      'Authorization' => "Basic #{ENV['JIRA_API_TOKEN']}",
      'Content-Type' => 'application/json'
    }
    request = Net::HTTP::Get.new(uri, headers)
    Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
      http.request(request)
    end
  end

  def format_name(text)
    formatted_str = text.gsub(/[^a-zA-Z]/, ' ')
    words = formatted_str.split(' ')
    words.map(&:capitalize).join(' ')
  end

  def format_email(assignee_name)
    domain = 'inspiregroup.io'
    email_prefix = assignee_name.sub(/\s/, '.').delete(' ').downcase
    assignee_email = "#{email_prefix}@#{domain}"
    return assignee_email
  end

  private

  def add_initial_breadcrumbs
    breadcrumbs.add "Home", root_path
  end

end
