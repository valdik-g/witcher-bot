class UpdateInventoryToPassports < ActiveRecord::Migration[7.0]
  def change
    change_column :passports, :inventory, :string, default: ""
  end
end
