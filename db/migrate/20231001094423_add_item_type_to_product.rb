class AddItemTypeToProduct < ActiveRecord::Migration[7.0]
  def change
    add_column :products, :item_type, :string
  end
end
