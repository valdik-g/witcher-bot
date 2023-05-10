# frozen_string_literal: true

# module for updating history of user
module UpdateHistory
  def update_history(message, bot, user)
    if user.passport_id.nil?
      bot.api.send_message(chat_id: message.chat.id,
                           text: 'Похоже к вам еще не привязан паспорт, используйте кнопку ' \
                                 'Получить свой паспорт')
    else
      history = user.passport.history
      if history.empty?
        history = "История вашего персонажа пуста, самое время это исправить!\n" \
                  'Введите историю вашего персонажа'
      end
      bot.api.send_message(chat_id: message.chat.id, text: history)
      bot.api.send_message(chat_id: message.chat.id, text: 'Введите новую историю',
                           reply_markup: cancel_markup)
      user.update(step: 'change_history')
    end
  end

  def change_history(message, bot, user)
    user.passport.update(history: message.text)
    return_buttons(user, bot, message.chat.id, 'История обновлена')
  end
end
