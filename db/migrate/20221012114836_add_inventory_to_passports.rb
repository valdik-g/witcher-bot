class AddInventoryToPassports < ActiveRecord::Migration[7.0]
  def change
    add_column :passports, :inventory, :string
  end
end
