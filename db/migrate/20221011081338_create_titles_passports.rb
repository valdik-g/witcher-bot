class CreateTitlesPassports < ActiveRecord::Migration[7.0]
  def change
    create_table :titles_passports do |t|
      t.integer :title_id
      t.integer :passport_id

      t.timestamps
    end
  end
end
