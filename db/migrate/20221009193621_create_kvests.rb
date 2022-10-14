class CreateKvests < ActiveRecord::Migration[7.0]
  def change
    create_table :kvests do |t|
      t.string :kvest_name
      t.string :description
      t.integer :necessary_level
      t.integer :crons_reward
      t.string :title_reward
      t.string :additional_reward

      t.timestamps
    end
  end
end
