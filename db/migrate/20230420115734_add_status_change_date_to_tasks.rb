class AddStatusChangeDateToTasks < ActiveRecord::Migration[7.0]
  def change
    add_column :tasks, :status_change_date, :datetime
  end
end
