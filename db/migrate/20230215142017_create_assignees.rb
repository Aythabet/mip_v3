class CreateAssignees < ActiveRecord::Migration[7.0]
  def change
    create_table :assignees do |t|
      t.string :name
      t.string :email
      t.boolean :admin

      t.timestamps
    end
  end
end
