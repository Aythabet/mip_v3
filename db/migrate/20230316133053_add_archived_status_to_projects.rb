class AddArchivedStatusToProjects < ActiveRecord::Migration[7.0]
  def change
    add_column :projects, :archived_status, :boolean, default: false
  end
end
