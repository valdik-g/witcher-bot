class CreateProducts < ActiveRecord::Migration[7.0]
  def change
    create_table :products do |t|
      t.string :item
      t.integer :cost
      t.integer :quantity

      t.timestamps
    end
  end
end
