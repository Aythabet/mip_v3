class CreateTaskWorklogs < ActiveRecord::Migration[7.0]
  def change
    create_table :task_worklogs do |t|
      t.string :author
      t.string :duration
      t.datetime :created
      t.datetime :updated
      t.datetime :started
      t.string :status
      t.references :task, null: false, foreign_key: true

      t.timestamps
    end
  end
end
