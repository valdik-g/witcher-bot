class UpdateHistoryToPassports < ActiveRecord::Migration[7.0]
  def change
    change_column :passports, :history, :string, default: ""
  end
end
