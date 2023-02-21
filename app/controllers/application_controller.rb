class ApplicationController < ActionController::Base
  before_action :authenticate_user!
  include ActionView::Helpers::NumberHelper

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
end
