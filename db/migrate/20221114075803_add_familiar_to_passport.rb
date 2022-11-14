class AddFamiliarToPassport < ActiveRecord::Migration[7.0]
  def change
    add_column :passports, :familiar, :string, default: "Фамальяр еще не получен"
  end
end
