class AddSentenceToTaskWorklogs < ActiveRecord::Migration[7.0]
  def up
    add_column :task_worklogs, :sentence, :string

    TaskWorklog.find_each do |worklog|
      author = worklog.author
      duration = worklog.duration
      created = worklog.created.strftime("%B %d, %Y at %I:%M %p")
      updated = worklog.updated
      started = worklog.started
      status = worklog.status
      jira_id = Task.find_by(id: worklog.task_id).jira_id


      sentence = "#{jira_id} - #{status}: #{author} logged #{duration} at #{created}."
      worklog.update(sentence: sentence)
    end
  end

  def down
    remove_column :task_worklogs, :sentence
  end
end
