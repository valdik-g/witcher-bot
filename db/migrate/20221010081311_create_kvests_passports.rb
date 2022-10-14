class CreateKvestsPassports < ActiveRecord::Migration[7.0]
  def change
    create_table :kvests_passports do |t|
      t.integer :kvest_id
      t.integer :passport_id

      t.timestamps
    end
  end
end
