class AddReferenceAssigneesinTasks < ActiveRecord::Migration[7.0]
  def change
    add_foreign_key :tasks, :assignees
  end
end
