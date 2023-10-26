class AddActiveToAssignees < ActiveRecord::Migration[7.0]
  def change
    add_column :assignees, :active, :boolean
  end
end
