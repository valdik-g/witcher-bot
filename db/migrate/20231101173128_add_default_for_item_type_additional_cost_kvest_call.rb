class AddDefaultForItemTypeAdditionalCostKvestCall < ActiveRecord::Migration[7.0]
  def change
    change_column :products, :item_type, :string, :default => ''
    change_column :products, :additional_cost, :string, :default => ''
    change_column :passports, :kvest_call, :integer, :default => 0
  end
end
