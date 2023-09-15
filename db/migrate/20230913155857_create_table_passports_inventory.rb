class CreateTablePassportsInventory < ActiveRecord::Migration[7.0]
  def change
    create_table :table_passports_inventories do |t|
      t.integer :passport_id
      t.integer :inventory_id
      t.integer :quantity

      t.timestamps
    end
  end
end
