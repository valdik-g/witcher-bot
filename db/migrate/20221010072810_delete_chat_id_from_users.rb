class DeleteChatIdFromUsers < ActiveRecord::Migration[7.0]
  def change
    remove_column :users, :chat_id
  end
end
