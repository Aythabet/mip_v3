class CreateTaskChangelogs < ActiveRecord::Migration[7.0]
  def change
    create_table :task_changelogs do |t|
      t.string :changelog_id
      t.string :author
      t.string :field
      t.string :from_value
      t.string :to_value
      t.datetime :timestamp
      t.references :task, null: false, foreign_key: true

      t.timestamps
    end
  end
end
