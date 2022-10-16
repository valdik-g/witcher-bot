class UpdateAdditionalKvestToPassports < ActiveRecord::Migration[7.0]
  def change
    change_column :passports, :additional_kvest, :integer, default: 0
  end
end
