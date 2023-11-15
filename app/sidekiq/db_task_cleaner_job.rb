class DbTaskCleanerJob
  include Sidekiq::Job

  sidekiq_options retry: 1

  def perform
    job_start_time = Time.now

    update_projects_archived_statuses
    check_if_assignee_is_active
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

    puts "Checking tasks and comparing with source...."
    puts "OK count: #{ok_count}"
    puts "NOK count: #{nok_count}, these are deleted."
    puts "We are up to date with source"

    job_end_time = Time.now
    JobsLog.create!(title: "DbTaskCleanerScheduler", execution_time: (job_end_time - job_start_time))
  end

  private

  def call_jira_api(url)
    uri = URI.parse(url)
    headers = {
      "Authorization" => "Basic #{ENV["JIRA_API_TOKEN"]}",
      "Content-Type" => "application/json",
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

      if response.code == "200"
        issues = JSON.parse(response.body)["issues"]
        break if issues.empty?

        keys += issues.map { |issue| issue["key"] }
        start_at += max_results
      else
        raise "Failed to fetch Jira issues. Response code: #{response.code}"
      end
    end

    keys
  end

  def check_if_assignee_is_active
    assignees = Assignee.all
    projects = Project.all

    assignees.each do |assignee|
      active = false # Default to inactive
      projects.each do |project|
        assignees_tasks = Task.where(project_id: project.id, assignee_id: assignee.id)
          .where("extract(year from created_at) = ?", 2023)
        if assignees_tasks.any?
          active = true
          break # No need to continue searching in other projects
        end
      end

      assignee.update(active: active)
      pp("Assignee #{assignee.name} is #{active ? "active" : "inactive"}")
    end
  end

  def update_projects_archived_statuses
    projects = Project.all

    projects.each do |project|
      updated_tasks = project.tasks.where("extract(month from last_jira_update) = ?", Date.today.month)

      archived_status = !updated_tasks.present?

      project.update(archived_status: archived_status)
      puts "Project #{project.name} is #{archived_status ? "archived" : "still active"}"
    end
  end
end
