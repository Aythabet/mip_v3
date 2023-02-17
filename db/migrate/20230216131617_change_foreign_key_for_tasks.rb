class ChangeForeignKeyForTasks < ActiveRecord::Migration[7.0]
  def change
    rename_column :tasks, :projects_id, :project_id
  end
end
