class CreateTableInventory < ActiveRecord::Migration[7.0]
  def change
    create_table :table_inventories do |t|
      t.string :item_name

      t.timestamps
    end
  end
end
