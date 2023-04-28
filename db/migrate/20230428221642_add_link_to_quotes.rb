class AddLinkToQuotes < ActiveRecord::Migration[7.0]
  def change
    add_column :quotes, :link, :string
  end
end
