class AddReasonToVacations < ActiveRecord::Migration[7.0]
  def change
    add_column :vacations, :reason, :string
  end
end
