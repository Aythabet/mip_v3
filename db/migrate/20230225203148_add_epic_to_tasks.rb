class AddEpicToTasks < ActiveRecord::Migration[7.0]
  def change
    add_column :tasks, :epic, :string
  end
end
