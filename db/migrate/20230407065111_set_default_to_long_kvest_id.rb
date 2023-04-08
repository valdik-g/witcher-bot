class SetDefaultToLongKvestId < ActiveRecord::Migration[7.0]
  def change
    change_column :passports, :long_kvest_id, :integer, default: nil
  end
end
