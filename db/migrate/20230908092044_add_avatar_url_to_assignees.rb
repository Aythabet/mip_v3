class AddAvatarUrlToAssignees < ActiveRecord::Migration[7.0]
  def change
    add_column :assignees, :avatar_url, :string
  end
end
