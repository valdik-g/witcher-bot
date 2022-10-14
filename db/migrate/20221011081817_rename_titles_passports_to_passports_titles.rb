class RenameTitlesPassportsToPassportsTitles < ActiveRecord::Migration[7.0]
  def change
    rename_table :titles_passports, :passports_titles
  end
end
