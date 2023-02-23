class DeleteTimeSpentColumnInTasks < ActiveRecord::Migration[7.0]
  def change
    remove_column :tasks, :time_spent
  end
end
