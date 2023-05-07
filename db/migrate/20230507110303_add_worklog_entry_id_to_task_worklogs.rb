class AddWorklogEntryIdToTaskWorklogs < ActiveRecord::Migration[7.0]
  def change
    add_column :task_worklogs, :worklog_entry_id, :integer
  end
end
