require 'sidekiq-scheduler'

class DbTaskCleanerScheduler
  include Sidekiq::Worker

  def perform
    entity_name = "agenceinspire"
    jira_ids_in_database = Task.pluck(:jira_id)
    jira_keys_in_jira = collect_keys_from_api(entity_name)

    ok_count = 0
    nok_count = 0

    jira_ids_in_database.each do |jira_id|
      if jira_keys_in_jira.include?(jira_id)
        ok_count += 1
      else
        Task.find_by(jira_id: jira_id).delete
        nok_count += 1
      end
    end

    puts "OK count: #{ok_count}"
    puts "NOK count: #{nok_count}, these are deleted."
    puts "We are up to date with source"
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

  def collect_keys_from_api(entity_name)
    keys = []
    start_at = 0
    max_results = 50

    pp("This might take up to 5 minutes... please wait")
    loop do
      response = call_jira_api("https://#{entity_name}.atlassian.net/rest/api/3/search?jql=ORDER%20BY%20updated&startAt=#{start_at}&maxResults=#{max_results}")

      if response.code == '200'
        issues = JSON.parse(response.body)['issues']
        break if issues.empty?

        keys += issues.map { |issue| issue['key'] }
        start_at += max_results
      else
        raise "Failed to fetch Jira issues. Response code: #{response.code}"
      end
    end

    keys
  end
end
