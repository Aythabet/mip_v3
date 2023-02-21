class AddSummaryToTasks < ActiveRecord::Migration[7.0]
  def change
    add_column :tasks, :summary, :text
  end
end
