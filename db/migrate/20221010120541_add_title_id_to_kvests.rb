class AddTitleIdToKvests < ActiveRecord::Migration[7.0]
  def change
    add_column :kvests, :title_id, :integer
    remove_column :kvests, :title_reward
  end
end
