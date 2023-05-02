class AddTaskTypeToTasks < ActiveRecord::Migration[7.0]
  def change
    add_column :tasks, :task_type, :string
  end
end
