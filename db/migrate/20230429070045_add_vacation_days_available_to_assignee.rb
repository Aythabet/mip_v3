class AddVacationDaysAvailableToAssignee < ActiveRecord::Migration[7.0]
  def change
    add_column :assignees, :vacation_days_available, :float
  end
end
