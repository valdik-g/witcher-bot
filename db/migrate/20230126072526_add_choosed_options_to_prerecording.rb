class AddChoosedOptionsToPrerecording < ActiveRecord::Migration[7.0]
  def change
    add_column :prerecordings, :choosed_options, :string, default: ''
  end
end
