class AddStepToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :step, :string
    rename_column :users, :usename, :username
  end
end
