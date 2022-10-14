class AddLevelRewardToKvets < ActiveRecord::Migration[7.0]
  def change
    add_column :kvests, :level_reward, :integer
  end
end
