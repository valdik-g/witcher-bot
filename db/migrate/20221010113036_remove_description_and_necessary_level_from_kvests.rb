class RemoveDescriptionAndNecessaryLevelFromKvests < ActiveRecord::Migration[7.0]
  def change
    remove_column :kvests, :description
    remove_column :kvests, :necessary_level
  end
end
