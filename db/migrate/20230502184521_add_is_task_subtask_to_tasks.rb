class AddIsTaskSubtaskToTasks < ActiveRecord::Migration[7.0]
  def change
    add_column :tasks, :is_task_subtask, :string
  end
end
