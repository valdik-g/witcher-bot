class RenameTablePassportsBuffsToBuffsPassports < ActiveRecord::Migration[7.0]
  def change
    rename_table :passports_buffs, :buffs_passports
  end
end
