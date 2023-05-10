class AddPrerecordingInfo < ActiveRecord::Migration[7.0]
  def change
    add_column :prerecordings, :closed_prerecordings, :string, default: ''
    add_column :prerecordings, :available_trainings, :string, default: ''
  end
end
