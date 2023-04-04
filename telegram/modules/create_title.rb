module CreateTitle
  def create_title(message, bot, user, cancel_markup)
    if user.admin
        bot.api.send_message(chat_id: message.chat.id, text: 'Введите название титула',
                             reply_markup: cancel_markup)
        user.update(step: 'input_title_name')
      else
        bot.api.send_message(chat_id: message.chat.id, text: 'Ты как сюда залез?)')
      end
  end

  def input_title_name(message, bot, user)
    bot.api.send_message(chat_id: message.chat.id, text: 'Введите описание титула')
    user.update(step: 'input_title_description')
    message.text
  end

  def input_title_description(message, bot, user, title_name)
    Title.create(title_name: title_name, description: message.text)
    return_buttons(user, bot, message.chat.id, "Титул #{title_name} создан")
    user.update(step: nil)
  end
end