# frozen_string_literal: true

# module for getting your history
module GetHistory
  def get_history(message, bot, user)
    if user.passport_id.nil?
      bot.api.send_message(chat_id: message.chat.id,
                           text: 'Похоже к вам еще не привязан паспорт, используйте кнопку ' \
                                 'Получить свой паспорт')
    else
      history = user.passport.history
      history = 'История вашего персонажа пуста' if history.empty?
      bot.api.send_message(chat_id: message.chat.id, text: history)
    end
  end
end
