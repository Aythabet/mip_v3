class AddCascadeDeletion < ActiveRecord::Migration[7.0]
  def change
    remove_foreign_key :task_worklogs, :tasks
    remove_foreign_key :task_changelogs, :tasks

    add_foreign_key :task_worklogs, :tasks, on_delete: :cascade
    add_foreign_key :task_changelogs, :tasks, on_delete: :cascade
  end
end
