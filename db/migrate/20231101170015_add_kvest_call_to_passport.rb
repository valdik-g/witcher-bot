class AddKvestCallToPassport < ActiveRecord::Migration[7.0]
  def change
    add_column :passports, :kvest_call, :integer
  end
end
