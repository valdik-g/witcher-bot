class CreatePassports < ActiveRecord::Migration[7.0]
  def change
    create_table :passports do |t|
      t.string :nickname
      t.integer :crons
      t.string :description
      t.string :school
      t.integer :level
      t.string :rank
      t.boolean :additional_kvest

      t.timestamps
    end
  end
end
