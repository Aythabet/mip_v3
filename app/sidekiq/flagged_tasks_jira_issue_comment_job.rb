class FlaggedTasksJiraIssueCommentJob
  include Sidekiq::Job

  sidekiq_options retry: 1

  def perform(task)
    task = Task.find(task)
    post_comment_to_task(task)
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

  def post_comment_to_task(task)
    task_comment_information = retrieve_task_assignee_name_and_account_id_to_comment(task.jira_id)
    displayName = task_comment_information[0]
    account_id = task_comment_information[1]
    url = "https://agenceinspire.atlassian.net/rest/api/3/issue/#{task.jira_id}/comment"
    uri = URI.parse(url)

    body_data = {
      "body": {
        "type": "doc",
        "version": 1,
        "content": [
          {
            "type": "paragraph",
            "content": [
              {
                "type": "text",
                "text": "Hello ",
              },
              {
                "type": "mention",
                "attrs": {
                  "id": "#{account_id}",
                  "text": "@#{displayName}",
                  "userType": "DEFAULT",
                },
              },
              {
                "type": "text",
                "text": ": Merci de saisir l'estimation et le suivi temporel",
              },
            ],
          },
        ],
      },
    }

    body_data_json = body_data.to_json  # Convert to JSON format
    headers = {
      "Authorization" => "Basic #{ENV["JIRA_API_TOKEN"]}",
      "Content-Type" => "application/json",
    }

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Post.new(uri.path, headers)
    request.body = body_data_json  # Assign the JSON string

    @response = http.request(request)

    pp("~~~~~~ Comment posted on JIRA for the task #{task.jira_id} ~~~~~~")
  end

  def retrieve_task_assignee_name_and_account_id_to_comment(jira_id)
    url = "https://agenceinspire.atlassian.net/rest/api/3/issue/#{jira_id}"
    response = call_jira_api(url)
    return unless response.code == "200"

    task_json_body = JSON.parse(response.body)
    displayName = task_json_body["fields"]["assignee"]["displayName"]
    account_id = task_json_body["fields"]["assignee"]["accountId"]

    task_comment_information = [displayName, account_id]
  end
end
