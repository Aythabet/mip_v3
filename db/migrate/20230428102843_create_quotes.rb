class CreateQuotes < ActiveRecord::Migration[7.0]
  def change
    create_table :quotes do |t|
      t.string :number
      t.date :date
      t.float :value
      t.string :recipient
      t.string :responsible
      t.string :status
      t.references :project, null: false, foreign_key: true

      t.timestamps
    end
  end
end
