class AddTelegramNickToPassportss < ActiveRecord::Migration[7.0]
  def change
    add_column :passports, :telegram_id, :string
  end
end
