class CreateTournaments < ActiveRecord::Migration[7.0]
  def change
    create_table :tournaments do |t|
      t.integer :crons
      t.integer :additional_kvest
      t.integer :repeat_kvest
      t.string :pairs
      t.string :winneres

      t.timestamps
    end
  end
end
