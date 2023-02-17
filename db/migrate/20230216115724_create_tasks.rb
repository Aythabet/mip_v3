class CreateTasks < ActiveRecord::Migration[7.0]
  def change
    create_table :tasks do |t|
      t.string :jira_id
      t.string :time_forecast
      t.string :time_spent
      t.string :status
      t.references :projects, null: false, foreign_key: true
      t.references :users, null: true, foreign_key: true

      t.timestamps
    end
  end
end
