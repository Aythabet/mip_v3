class RemoveTotalWorkingHoursFromAssignees < ActiveRecord::Migration[7.0]
  def change
    remove_column :assignees, :total_working_hours, :float
  end
end
