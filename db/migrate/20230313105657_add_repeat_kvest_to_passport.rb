class AddRepeatKvestToPassport < ActiveRecord::Migration[7.0]
  def change
    add_column :passports, :kvest_repeat, :integer, default: 0
    add_column :kvests, :additional_kvest, :integer, default: 0
    add_column :kvests, :kvest_repeat, :integer, default: 0
  end
end
