class RenameTelegramIdToPassports < ActiveRecord::Migration[7.0]
  def change
    rename_column :passports, :telegram_id, :telegram_nick
  end
end
