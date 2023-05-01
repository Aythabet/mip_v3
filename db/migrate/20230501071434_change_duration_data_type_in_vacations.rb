class ChangeDurationDataTypeInVacations < ActiveRecord::Migration[6.1]
  def change
    change_column :vacations, :duration, :float
  end
end
