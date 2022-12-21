class CreateUserPrerecording < ActiveRecord::Migration[7.0]
  def change
    create_table :user_prerecordings do |t|
      t.integer :passport_id
      t.string :days, default: ''
      t.integer :message_id
      t.boolean :voted, default: false

      t.timestamps
    end
  end
end
