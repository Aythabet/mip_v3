class AddAccountIdToAssignees < ActiveRecord::Migration[7.0]
  def change
    add_column :assignees, :account_id, :bigint
  end
end
