class AddLongKvestToPassportss < ActiveRecord::Migration[7.0]
  def change
    add_column :passports, :long_kvest_id, :integer, default: 0
  end
end
