class AddDefaultValueToTimeVariablesInTasks < ActiveRecord::Migration[7.0]
  def change
    change_column_default :tasks, :time_forecast, 0
    change_column_default :tasks, :time_spent, 0
  end
end
