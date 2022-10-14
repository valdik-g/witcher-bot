class AddHistoryToPassports < ActiveRecord::Migration[7.0]
  def change
    add_column :passports, :history, :string
  end
end
