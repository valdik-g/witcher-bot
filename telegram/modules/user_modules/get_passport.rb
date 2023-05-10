# frozen_string_literal: true

# module for getting users passport
module GetPassport

  def get_passport(message, bot, user)
    if user.passport_id.nil?
      passport = Passport.find_by(telegram_nick: user.username)
      if passport.nil?
        bot.api.send_message(chat_id: message.chat.id,
                             text: 'Кажется ваш паспорт еще не существует, обратитесь к Анри Виллу')
      else
        user.update(passport_id: passport.id, step: 'input_bd')
        bot.api.send_message(chat_id: message.chat.id,
                             text: 'Мы нашли ваш паспорт, однако предварительно нужно собрать ' \
                                   "немного ифнормации о вас\nВведите дату рождения(формат 03.12):")
      end
    elsif user.passport.bd.empty?
      bot.api.send_message(chat_id: message.chat.id,
                           text: 'Мы нашли ваш паспорт, однако предварительно нужно собрать ' \
              "немного ифнормации о вас\nВведите дату рождения(формат 03.12):")
      user.update(step: 'input_bd')
    else
      bot.api.send_message(chat_id: message.chat.id, text: output_passport(user.passport_id, user),
                           reply_markup: passport_markup)
    end
  end

  def input_bd(message, bot, user)
    bot.api.send_message(chat_id: message.chat.id, text: 'Введите адрес электронной почты:')
    user.update(step: 'input_mail')
    message.text
  end

  def input_mail(message, bot, user)
    bot.api.send_message(chat_id: message.chat.id, text: 'Введите номер телефона:')
    user.update(step: 'input_number')
    message.text
  end

  def input_number(message, bot, user, bd, mail)
    user.passport.update(bd: bd, mail: mail, number: message.text)
    bot.api.send_message(chat_id: message.chat.id, text: output_passport(user.passport_id, user),
                         reply_markup: passport_markup)
    user.update(step: nil)
  end

  def passport_markup
    Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: [
      Telegram::Bot::Types::InlineKeyboardButton.new(
        text: 'Открыть инвентарь', callback_data: 'inventory'
      )
    ])
  end
end
