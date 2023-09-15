class RenameTables < ActiveRecord::Migration[7.0]
  def change
    rename_table :table_inventories, :inventories
    rename_table :table_passports_inventories, :passports_inventories
  end 
end
