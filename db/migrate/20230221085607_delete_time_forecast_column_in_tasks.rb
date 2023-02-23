class DeleteTimeForecastColumnInTasks < ActiveRecord::Migration[7.0]
  def change
    remove_column :tasks, :time_forecast

  end
end
