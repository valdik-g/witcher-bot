class RenameTableBuffToBuffs < ActiveRecord::Migration[7.0]
  def change
    rename_table :buff, :buffs
    rename_table :buffs_passports, :passports_buffs
  end
end
