class AddPassportIdToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :passport_id, :integer, default: nil
  end
end
