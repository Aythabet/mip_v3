class AddExecutionTimeToJobsLog < ActiveRecord::Migration[7.0]
  def change
    add_column :jobs_logs, :execution_time, :float
  end
end
