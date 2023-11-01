class AddAdditionalCostToProduct < ActiveRecord::Migration[7.0]
  def change
    add_column :products, :additional_cost, :string
  end
end
