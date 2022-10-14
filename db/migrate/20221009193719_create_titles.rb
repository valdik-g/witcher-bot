class CreateTitles < ActiveRecord::Migration[7.0]
  def change
    create_table :titles do |t|
      t.string :title_name
      t.string :description

      t.timestamps
    end
  end
end
