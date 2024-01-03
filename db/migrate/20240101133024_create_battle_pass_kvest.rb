class CreateBattlePassKvest < ActiveRecord::Migration[7.0]
  def change
    create_table :battle_pass_kvests do |t|
      t.integer :crons_reward
      t.integer :title_id
      t.integer :additional_kvest
      t.integer :kvest_repeat
      t.integer :kvest_call

      t.timestamps
    end
  end
end
