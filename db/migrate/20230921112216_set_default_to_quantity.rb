class SetDefaultToQuantity < ActiveRecord::Migration[7.0]
  def change
    change_column :passports_inventories, :quantity, :integer, default: 0
  end
end
