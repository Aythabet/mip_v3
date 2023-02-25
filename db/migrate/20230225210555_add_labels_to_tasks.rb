class AddLabelsToTasks < ActiveRecord::Migration[7.0]
  def change
    add_column :tasks, :labels, :string
  end
end
