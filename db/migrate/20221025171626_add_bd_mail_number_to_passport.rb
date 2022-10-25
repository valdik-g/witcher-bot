class AddBdMailNumberToPassport < ActiveRecord::Migration[7.0]
  def change
    add_column :passports, :bd, :string, default: ""
    add_column :passports, :mail, :string, default: ""
    add_column :passports, :number, :string, default: ""
  end
end
