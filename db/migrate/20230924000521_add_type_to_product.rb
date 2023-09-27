class AddTypeToProduct < ActiveRecord::Migration[7.0]
  def change
    add_column :products, :type, :string
    change_table :products do |t|
      t.change :cost, :string
    end
  end
end
