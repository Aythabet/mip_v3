class AddOnVacationToAssignee < ActiveRecord::Migration[7.0]
  def change
    add_column :assignees, :on_vacation, :boolean
  end
end
