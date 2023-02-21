class AddTimeColumnsToTasks < ActiveRecord::Migration[7.0]
  def change
    add_column :tasks, :time_spent, :float, default: 0.0
    add_column :tasks, :time_forecast, :float, default: 0.0
  end
end
