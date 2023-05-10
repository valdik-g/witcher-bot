# frozen_string_literal: true

module CreatePassports
  def create_passport(message, bot, user)
    if user.admin
      bot.api.send_message(chat_id: message.chat.id, text: 'Введите имя будующего ведьмака:',
                          reply_markup: cancel_markup)
      user.update(step: 'input_name')
    else
      bot.api.send_message(chat_id: message.chat.id, text: 'Ты как сюда залез?)')
    end
  end

  def input_name(message, bot, user)
    bot.api.send_message(chat_id: message.chat.id, text: 'Введите школу:')
    user.update(step: 'input_school')
    message.text
  end

  def input_school(message, bot, user, witcher_name)
    school = message.text
    bot.api.send_message(chat_id: message.chat.id, text: 'Введите ник пользователя в телеграмм')
    user.update(step: 'input_telegram_nick')
    Passport.create(nickname: witcher_name, crons: 0, school: school,
      level: 0, rank: 'Рекрут', description: 'Отсутствует', elixirs: 'Нет')
  end

  def input_telegram_nick(message, bot, user, passport)
    telegram_nick = message.text
    passport.update(telegram_nick: telegram_nick)
    User.find_by(username: telegram_nick)&.update(passport_id: passport.id)
    return_buttons(user, bot, message.chat.id, 'Запись создана')
  end
end
