class AddAdditionalRewardToTournament < ActiveRecord::Migration[7.0]
  def change
    add_column :tournaments, :additional_reward, :string
  end
end
