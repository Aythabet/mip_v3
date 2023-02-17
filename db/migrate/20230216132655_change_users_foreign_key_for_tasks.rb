class ChangeUsersForeignKeyForTasks < ActiveRecord::Migration[7.0]
  def change
    rename_column :tasks, :users_id, :user_id
  end
end
