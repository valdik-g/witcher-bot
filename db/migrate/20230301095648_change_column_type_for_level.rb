class ChangeColumnTypeForLevel < ActiveRecord::Migration[7.0]
  def change
    change_table :passports do |t|
      t.change :level, :string
    end
  end
end
