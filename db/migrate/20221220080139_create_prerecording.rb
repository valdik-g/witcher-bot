class CreatePrerecording < ActiveRecord::Migration[7.0]
  def change
    create_table :prerecordings do |t|
      t.boolean :closed, default: false

      t.timestamps
    end
  end
end
