class CreateTableBuffsToPassports < ActiveRecord::Migration[7.0]
  def change
    create_table :buffs_passports do |t|
      t.integer :buff_id, default: nil
      t.integer :passport_id, default: nil

      t.timestamps
    end
  end
end
