# frozen_string_literal: true

# module for sending info about player, such as bd, nickname, phone number etc.
module PlayerInfo
  def player_info(message, bot, user)
    output_all_passports(bot, message.chat.id)
    bot.api.send_message(chat_id: message.chat.id, text: 'Выберите паспорт', reply_markup: cancel_markup)
    user.update(step: 'input_abon_info')
  end

  def input_abon_info(message, bot, user)
    passport = Passport.find_by(id: message.text)
    if passport.nil?
      return_buttons(user, bot, message.chat.id, 'Некорректный ввод, повторите команду')
    else
      return_buttons(user, bot, message.chat.id,
                     "Имя: #{passport.nickname}\nДень рождения: #{passport.bd}\nНомер телефона: " \
                     "#{passport.number}\nОстаток абонемента: #{passport.subscription}\nДолг:#{passport.debt}")
    end
  end
end
