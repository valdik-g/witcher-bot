class AddBuffsToPassports < ActiveRecord::Migration[7.0]
  def change
    create_table :buff do |t|
      t.string :buff_name, default: ''
      t.string :buff_description, default: ''
      
      t.timestamps
    end
  end
end
