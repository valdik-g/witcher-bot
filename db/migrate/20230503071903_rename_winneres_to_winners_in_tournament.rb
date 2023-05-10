class RenameWinneresToWinnersInTournament < ActiveRecord::Migration[7.0]
  def change
    rename_column :tournaments, :winneres, :winners
  end
end
