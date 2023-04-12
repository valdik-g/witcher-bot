# frozen_string_literal: true

# module for getting users subscription info
module GetSubscription
  def get_subscription(message, bot, user)
    if user.passport_id.nil?
      bot.api.send_message(chat_id: message.chat.id,
                           text: 'Похоже к вам еще не привязан паспорт, используйте кнопку Получить свой паспорт')
    elsif user.passport.subscription.to_i >= 500
      bot.api.send_message(chat_id: message.chat.id, text: "\xF0\x9F\x8E\x89 Поздравляю! Ты блатной")
    else
      sale_markup_buttons = [
        Telegram::Bot::Types::InlineKeyboardButton.new(text: 'Хочу 30%', url: 'tg://user?id=612352098')
      ]
      sale_markup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: sale_markup_buttons)
      subscription = user.passport.subscription
      debt = user.passport.debt
      subs_message = "\xF0\x9F\x92\xB3 Абонемент: "
      subs_message += if subscription != 0
                        "Осталось #{subscription} посещений(я)"
                      else
                        "Кажется у вас нет абонемента.\n Внизу есть кнопочка чтобы получить скидку в 30%, " \
                                        "только \xF0\x9F\xA4\xAB"
                      end
      subs_message += "\n\xF0\x9F\x92\xB0 Долг: "
      subs_message += debt.positive? ? "#{debt}р" : "Кажется у вас нет долгов, так держать! \xF0\x9F\x8E\x89"
      bot.api.send_message(chat_id: message.chat.id, text: subs_message, reply_markup: sale_markup)
    end
  end
end
