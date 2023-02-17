class RemoveForeignKeyAssigneeIdinTasks < ActiveRecord::Migration[7.0]
  def change
    remove_foreign_key :tasks, :users
  end
end
