class TasksJob
  include Sidekiq::Job
  DEFAULT_USER_ID = 1
  DEFAULT_PORJECT_ID = 1

  def perform(*)
    entity = "agenceinspire"
    jira_ids = collect_all_task_jira_ids(entity)
    i = 0
    jira_ids.each do |jira_id|
      collect_and_save_task_information(entity, jira_id)
      i += 1
      pp("~~~~~~~~~ Task #{i} imported! ~~~~~~~~")
    end
  end

  private

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

  def collect_all_task_jira_ids(entity)
    jira_ids = []
    start_at = 0
    max_results = 50

    response = call_jira_api("https://#{entity}.atlassian.net/rest/api/3/search?jql=ORDER%20BY%20updated&startAt=#{start_at}&maxResults=#{max_results}")

    if response.code == '200'
      total_issues_count = JSON.parse(response.body)['total']
      total_pages = 1 #(total_issues_count / 50.0).ceil # Move under the total_issues_count when done.
      p("Total issues is #{total_issues_count}...")

      (1..total_pages).each do |i|
        tasks = JSON.parse(response.body)
        jira_ids << tasks['issues'].map { |issue| issue['key'] }
        start_at += max_results
        response = call_jira_api("https://#{entity}.atlassian.net/rest/api/3/search?jql=ORDER%20BY%20updated&startAt=#{start_at}&maxResults=#{max_results}")
      end
    end
    number_of_tasks_to_import = max_results * total_pages
    p("Total issues to import is #{number_of_tasks_to_import}...")
    p(" It will take #{number_of_tasks_to_import / 60} minutes...")
    jira_ids.flatten
  end

  def collect_and_save_task_information(entity, jira_id)
    url = "https://#{entity}.atlassian.net/rest/api/3/issue/#{jira_id}"
    response = call_jira_api(url)
    return unless response.code == '200'

    json_task = JSON.parse(response.body)
    fields = json_task['fields']
    added_task = Task.where(jira_id:).first_or_create
    added_task.update(
      project_id: determine_the_project_id(json_task),
      assignee_id: determine_the_user_id(json_task),
      time_forecast: fields['timeoriginalestimate'],
      status: fields&.[]('status')&.[]('name'),
      created_at: fields['created'],
      updated_at: fields['updated'],
      summary: fields['summary'],
      priority: fields&.[]('priority')&.[]('name'),
      epic: fields&.[]('parent')&.[]('fields')&.[]('summary'),
      time_spent: retrieve_time_spent(url),
      labels: retrive_labels(json_task)
    )
    pp(added_task)
    added_task.save
  end

  def determine_the_user_id(json_task)
    fields = json_task['fields']
    assignee_name = fields&.[]('assignee')&.[]('displayName')
    if assignee_name.nil? || assignee_name.empty?
      DEFAULT_USER_ID
    else
      assignee_name = format_name(assignee_name)
      assignee_email = format_email(assignee_name)
      assignee = Assignee.find_or_create_by(name: assignee_name, email: assignee_email)
      assignee.id || DEFAULT_USER_ID
    end
  end

  def determine_the_project_id(json_task)
    fields = json_task['fields']
    project_key = fields&.[]('project')&.[]('key')
    project_name = fields&.[]('project')&.[]('name')
    project_fields_response = call_jira_api(fields['project']['self']) # api call on the project it self to get the lead
    return unless project_fields_response.code == '200'

    json_project = JSON.parse(project_fields_response.body)
    project_lead = json_project['lead']['displayName']
    project = Project.find_or_create_by(jira_id: project_key) do |pro|
      pro.name = project_name
      pro.lead = project_lead
    end
    project.id || DEFAULT_PROJECT_ID
  end

  def retrieve_time_spent(url)
    worklog_url = "#{url}/worklog"
    worklog_response = call_jira_api(worklog_url)
    return unless worklog_response.code == '200'

    worklogs = JSON.parse(worklog_response.body)['worklogs']
    total_time_spent = 0
    worklogs.each do |worklog|
      time_spent_in_seconds = worklog['timeSpentSeconds'].to_i
      total_time_spent += time_spent_in_seconds
    end
    return total_time_spent
  end

  def retrive_labels(json_task)
    fields = json_task['fields']
    labels = fields&.[]('labels')
  end

end
