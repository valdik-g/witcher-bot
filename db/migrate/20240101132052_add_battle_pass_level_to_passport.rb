class AddBattlePassLevelToPassport < ActiveRecord::Migration[7.0]
  def change
    add_column :passports, :bp_level, :integer, default: 0
  end
end
