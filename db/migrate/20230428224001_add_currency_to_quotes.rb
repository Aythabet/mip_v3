class AddCurrencyToQuotes < ActiveRecord::Migration[7.0]
  def change
    add_column :quotes, :currency, :string
  end
end
