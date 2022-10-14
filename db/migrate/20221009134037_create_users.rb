class CreateUsers < ActiveRecord::Migration[7.0]
  def change
    create_table :users do |t|
      t.string :usename
      t.integer :telegram_id
      t.integer :chat_id

      t.timestamps
    end
  end
end
