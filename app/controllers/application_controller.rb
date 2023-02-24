class ApplicationController < ActionController::Base
  before_action :authenticate_user!
  include ActionView::Helpers::NumberHelper

  def format_duration(seconds)
    if seconds.nil? || seconds.zero?
      return "No input from assignee"
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

  private

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
end
