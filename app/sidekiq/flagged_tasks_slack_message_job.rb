class FlaggedTasksSlackMessageJob
  include Sidekiq::Job

  sidekiq_options retry: 1

  def perform(task)
    task = Task.find(task)
    user = task.assignee.name
    jira_id = task.jira_id
    nil_attributes = task.attributes.select { |_, value| value.nil? }.keys

    if nil_attributes.any?
      message = "Hello, #{user}!\n"
      message += "You have some missing fields in this task: <https://agenceinspire.atlassian.net/browse/#{jira_id}|#{jira_id}>\n"
      message += "Please fill them in and remember to update all yours ongoing tasks!\n"
      message += "Thanks  :sunglasses:  \n"
      send_slack_message(message, user)
    end
  end

  private

  def send_slack_message(message, username)
    client = Slack::Web::Client.new
    user_id = find_user_id(username)
    if user_id.nil?
      pp("User #{username} not found")
    else
      client.chat_postMessage(channel: user_id, text: message, as_user: true)
    end
  end

  def find_user_id(username)
    client = Slack::Web::Client.new
    users_list = client.users_list.members

    names = users_list.map do |member|
      display_name = member.profile&.display_name || member.name
      user_id = member.id
      { name: display_name, id: user_id }
    end

    user = names.find { |member| member[:name] == username }
    user_id = user[:id] unless user.nil?

    # Try different variations of the username if user_id is nil
    if user_id.nil?
      variations = [
        username,                          # Full name
        username.downcase,                 # Lowercase version
        username.split(" ").first,         # First word of the name
        username.split(" ").last,           # Last word of the name
      ]

      user_id = variations.map { |name| names.find { |member| member[:name] == name }&.dig(:id) }.compact.first
    end
    user_id
  end
end
