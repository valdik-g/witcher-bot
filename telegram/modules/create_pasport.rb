module CreatePassports

  def create_passport()
    if user.admin
        bot.api.send_message(chat_id: message.chat.id, text: 'Введите имя будующего ведьмака:', reply_markup: cancel_markup)
        user.update(step: 'input_name')
    else
      bot.api.send_message(chat_id: message.chat.id, text: 'Ты как сюда залез?)')
    end
  end

  def input_name()
    witcher_name = message.text
    bot.api.send_message(chat_id: message.chat.id, text: 'Введите школу:')
    user.update(step: 'input_school')
  end

  def input_school()
    school = message.text
    passport = Passport.create(nickname: witcher_name, crons: 0, school: school,
      level: 0, rank: 'Рекрут', additional_kvest: 0, description: 'Отсутствует',
      elixirs: 'Нет')
    bot.api.send_message(chat_id: message.chat.id, text: 'Введите ник пользователя в телеграмм')
    user.update(step: 'input_telegram_nick')
  end

  def input_telegram_nick()
    telegram_nick = message.text
    passport.update(telegram_nick: telegram_nick)
    update_user = User.find_by(username: telegram_nick)
    update_user&.update(passport_id: passport.id)
    return_buttons(user, bot, message.chat.id, 'Запись создана')
    user.update(step: nil)
  end
end