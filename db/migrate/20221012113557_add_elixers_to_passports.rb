class AddElixersToPassports < ActiveRecord::Migration[7.0]
  def change
    add_column :passports, :elixirs, :string
  end
end
