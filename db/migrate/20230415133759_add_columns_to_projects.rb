class AddColumnsToProjects < ActiveRecord::Migration[7.0]
  def change
    add_column :projects, :total_internal_cost, :decimal, precision: 10, scale: 2, default: 0.0
    add_column :projects, :total_selling_price, :decimal, precision: 10, scale: 2, default: 0.0
  end
end
