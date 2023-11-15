class TasksJob
  include Sidekiq::Job
  DEFAULT_USER_ID = 1
  DEFAULT_PORJECT_ID = 1

  def perform
    job_start_time = Time.now
    entity = "agenceinspire"
    jira_ids = collect_all_task_jira_ids(entity)
    i = 0
    jira_ids.each do |jira_id|
      collect_and_save_task_information(entity, jira_id)
      i += 1
      pp("~~~~~~~~~ Issue ##{i} imported and added to the database ~~~~~~~~")
    end
    job_end_time = Time.now
    JobsLog.create!(title: "TasksJob", execution_time: job_end_time - job_start_time)
  end

  private

  def format_name(text)
    formatted_str = text.gsub(/[^a-zA-Z]/, " ")
    words = formatted_str.split(" ")
    words.map(&:capitalize).join(" ")
  end

  def format_email(assignee_name)
    domain = "agence-inspire.com"
    email_prefix = assignee_name.sub(/\s/, ".").delete(" ").downcase
    assignee_email = "#{email_prefix}@#{domain}"
    return assignee_email
  end

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

  def collect_all_task_jira_ids(entity)
    jira_ids = []
    start_at = 0 # Change this if you need to update the starting point
    max_results = 50

    response = call_jira_api("https://#{entity}.atlassian.net/rest/api/3/search?jql=ORDER%20BY%20updated&startAt=#{start_at}&maxResults=#{max_results}")

    if response.code == "200"
      total_pages = 1 # (total_issues_count / 50.0).ceil # Move under the total_issues_count when done.
      total_issues_count = max_results * total_pages
      p("We're preparing the data for #{total_pages} pages... Please wait!")
      p("Total issues to update #{total_issues_count}...")

      (1..total_pages).each do
        tasks = JSON.parse(response.body)
        jira_ids << tasks["issues"].map { |issue| issue["key"] }
        start_at += max_results
        response = call_jira_api("https://#{entity}.atlassian.net/rest/api/3/search?jql=ORDER%20BY%20updated&startAt=#{start_at}&maxResults=#{max_results}")
      end
    end

    jira_ids.flatten
  end

  def collect_and_save_task_information(entity, jira_id)
    url = "https://#{entity}.atlassian.net/rest/api/3/issue/#{jira_id}"
    response = call_jira_api(url)
    return unless response.code == "200"

    json_task = JSON.parse(response.body)
    fields = json_task["fields"]
    added_task = Task.find_or_initialize_by(jira_id: jira_id)
    last_jira_update = fields["updated"]

    if added_task.last_jira_update != last_jira_update
      added_task.assign_attributes(
        project_id: determine_the_project_id(json_task),
        assignee_id: determine_the_user_id(json_task),
        time_forecast: fields["timeoriginalestimate"],
        status: fields&.dig("status", "name"),
        created_at: fields["created"],
        last_jira_update: last_jira_update,
        summary: fields["summary"],
        priority: fields&.dig("priority", "name"),
        epic: fields&.dig("parent", "fields", "summary"),
        time_spent: retrieve_time_spent(url),
        labels: retrive_labels(json_task),
        status_change_date: fields["statuscategorychangedate"],
        due_date: fields["duedate"],
        task_type: fields&.dig("issuetype", "name"),
        is_task_subtask: fields&.dig("issuetype", "subtask"),
        reporter: fields&.dig("reporter", "displayName"),
        flagged: false,
      )

      # pp("~~~~~~~~~ #{added_task.jira_id}: #{added_task.assignee.name} - Report to #{added_task.reporter}~~~~~~~~~")
      # pp("~~~~~~~~~ Importing next task's infos: #{retrieve_worklog_info(url, jira_id).count} Worklogs imported ~~~~~~~~~ ")
      added_task.save
    end
    retrieve_task_changelogs(jira_id)
    retrieve_worklog_info(url, jira_id)

    if check_task_forecast_and_time_spent(added_task)
      added_task.update!(flagged: true)
      pp("~~~~~~~~~  #{added_task.jira_id} has been flagged! ~~~~~~~~~")
    end
  end

  def determine_the_user_id(json_task)
    fields = json_task["fields"]
    account_id = fields&.[]("assignee")&.[]("accountId")
    assignee_name = fields&.[]("assignee")&.[]("displayName")

    if assignee_name.nil?
      assignee_name = "Inspire #{(0..999).to_a.sample}"
      assignee_email = "No Email"
      # pp("~~~~~~~~~  No name found for this assignee, default values assigned: #{assignee_name} ~~~~~~~~~")
    else
      assignee_name = format_name(assignee_name)
      assignee_email = format_email(assignee_name)
    end

    assignee = Assignee.find_or_create_by(name: assignee_name) do |assignee|
      assignee.account_id = account_id
      assignee.email = assignee_email
    end

    assignee.id || DEFAULT_USER_ID
  end

  def determine_the_project_id(json_task)
    fields = json_task["fields"]
    project_key = fields&.[]("project")&.[]("key")
    project_name = fields&.[]("project")&.[]("name")
    project_fields_response = call_jira_api(fields["project"]["self"]) # api call on the project it self to get the lead
    return unless project_fields_response.code == "200"

    json_project = JSON.parse(project_fields_response.body)
    project_lead = json_project["lead"]["displayName"]
    project = Project.find_or_create_by(jira_id: project_key) do |pro|
      pro.name = project_name
      pro.lead = project_lead
    end
    project.id || DEFAULT_PROJECT_ID
  end

  def retrieve_time_spent(url)
    worklog_url = "#{url}/worklog"
    worklog_response = call_jira_api(worklog_url)
    return unless worklog_response.code == "200"

    worklogs = JSON.parse(worklog_response.body)["worklogs"]
    total_time_spent = 0
    worklogs.each do |worklog|
      time_spent_in_seconds = worklog["timeSpentSeconds"].to_i
      total_time_spent += time_spent_in_seconds
    end
    return total_time_spent
  end

  def retrive_labels(json_task)
    fields = json_task["fields"]
    fields&.[]("labels")
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
      return "#{minutes.round(1)} min"
    end

    hours = minutes / 60.0
    if hours < 8
      return "#{hours.round(1)} h"
    end

    days = (hours / 8).floor
    hours %= 8
    hours = hours.round(1)

    duration = []
    duration << "#{days} day#{"s" if days > 1}" if days.positive?
    duration << "#{hours} hour#{"s" if hours > 1}" if hours.positive?
    duration.join(" and ")
  end

  def retrieve_worklog_info(url, jira_id)
    worklog_url = "#{url}/worklog"
    task = Task.find_by(jira_id: jira_id)

    return [] unless task && task.status # Check if task exists and status is not nil

    worklog_response = call_jira_api(worklog_url)
    return [] unless worklog_response.code == "200"

    worklogs = JSON.parse(worklog_response.body)["worklogs"]
    worklog_info = []

    worklogs.each do |worklog|
      existing_worklog = TaskWorklog.find_or_initialize_by(worklog_entry_id: worklog["id"])

      if existing_worklog.new_record?
        TaskWorklog.create!(
          author: worklog["author"]["displayName"],
          duration: worklog["timeSpentSeconds"],
          created: worklog["created"],
          updated: worklog["updated"],
          started: worklog["started"],
          status: task.status,
          task_id: task.id,
          worklog_entry_id: worklog["id"],
        )

        worklog_info << {
          author: worklog["author"]["displayName"],
          duration: worklog["timeSpentSeconds"],
          created: worklog["created"],
          updated: worklog["updated"],
          started: worklog["started"],
          status: task.status,
          task_id: task.id,
          worklog_entry_id: worklog["id"],
        }
      elsif existing_worklog.updated != worklog["updated"]
        existing_worklog.update!(
          author: worklog["author"]["displayName"],
          duration: worklog["timeSpentSeconds"],
          created: worklog["created"],
          updated: worklog["updated"],
          started: worklog["started"],
          status: task.status,
        )

        worklog_info << {
          author: worklog["author"]["displayName"],
          duration: worklog["timeSpentSeconds"],
          created: worklog["created"],
          updated: worklog["updated"],
          started: worklog["started"],
          status: task.status,
          task_id: task.id,
          worklog_entry_id: worklog["id"],
        }
      end
    end

    worklog_info
  end

  def retrieve_task_changelogs(jira_id)
    url = "https://agenceinspire.atlassian.net/rest/api/3/issue/#{jira_id}/changelog?maxResults=100&startAt=0"
    response = call_jira_api(url)
    i = 0
    return unless response.code == "200"

    task_changelogs = JSON.parse(response.body)
    task_changelogs["values"].each do |change|
      author = change["author"]["displayName"]
      timestamp = DateTime.parse(change["created"]).strftime("%B %d, %Y at %I:%M %p")

      change["items"].each do |item|
        field = item["field"]
        from_value = item["fromString"]
        to_value = item["toString"]

        # Check if the changelog already exists in the database
        existing_changelog = TaskChangelog.find_by(changelog_id: change["id"])

        # Create a new changelog if it doesn't exist
        if existing_changelog.nil?
          imported_changelog = TaskChangelog.create(
            changelog_id: change["id"],
            author: author,
            field: field,
            from_value: from_value,
            to_value: to_value,
            task_id: Task.find_by(jira_id: jira_id).id,
            timestamp: DateTime.parse(change["created"]),
          )
          i += 1
        end
      end
    end
    # pp("~~~~~~~~~ Importing next task's infos: #{i} Changelog(s) imported ~~~~~~~~~ ") if i > 0
  end

  def check_task_forecast_and_time_spent(task)
    (task.time_forecast.nil? || task.time_spent.nil?) && ["In Progress", "On hold"].include?(task.status)
  end
end
