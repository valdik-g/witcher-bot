class AddSumBpLevelToPassport < ActiveRecord::Migration[7.0]
  def change
    add_column :passports, :sum_bp_level, :integer, default: 0
  end
end
