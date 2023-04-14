class AddColumnsToAssignees < ActiveRecord::Migration[7.0]
  def change
    add_column :assignees, :salary, :float
    add_column :assignees, :total_working_hours, :integer, default: 40
    add_column :assignees, :hourly_rate, :float
  end
end
