class AddSubscriptionAndDebtToPassport < ActiveRecord::Migration[7.0]
  def change
    add_column :passports, :subscription, :integer, default: 0
    add_column :passports, :debt, :integer, default: 0
  end
end
