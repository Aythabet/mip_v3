class AddLastJiraUpdateToTasks < ActiveRecord::Migration[7.0]
  def change
    add_column :tasks, :last_jira_update, :datetime
  end
end
