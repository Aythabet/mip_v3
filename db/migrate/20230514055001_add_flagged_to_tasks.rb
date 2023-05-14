class AddFlaggedToTasks < ActiveRecord::Migration[7.0]
  def change
    add_column :tasks, :flagged, :boolean
  end
end
