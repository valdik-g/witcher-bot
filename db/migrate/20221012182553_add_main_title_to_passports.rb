class AddMainTitleToPassports < ActiveRecord::Migration[7.0]
  def change
    add_column :passports, :main_title_id, :integer
  end
end
