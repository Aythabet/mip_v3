class ChangeFkUsersonTasks < ActiveRecord::Migration[7.0]
  def change
    rename_column :tasks, :user_id, :assignee_id
  end
end
