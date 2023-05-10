class AddSentenceToTaskChangelogs < ActiveRecord::Migration[7.0]
  def up
    add_column :task_changelogs, :sentence, :string

    TaskChangelog.find_each do |changelog|
      jira_id = changelog.task.jira_id
      author = changelog.author
      field = changelog.field
      from_value = changelog.from_value
      to_value = changelog.to_value
      timestamp = changelog.timestamp.strftime("%B %d, %Y at %I:%M %p")

      sentence = "#{jira_id} - #{author} updated #{field} from '#{from_value}' to '#{to_value}' on #{timestamp}."
      changelog.update(sentence: sentence)
    end
  end

  def down
    remove_column :task_changelogs, :sentence
  end
end
