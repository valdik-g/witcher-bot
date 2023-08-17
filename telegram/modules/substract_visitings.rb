# frozen_string_literal: true

# module for substracting visiting from subscription
module SubstractVisitings
  def substract_visitings(message, bot, user)
    if user.admin
      output_all_passports(bot, message.chat.id)
      bot.api.send_message(chat_id: message.chat.id, text: 'Выберите тех, кто был на тренировке',
                           reply_markup: cancel_markup)
      user.update(step: 'input_substract')
    else
      bot.api.send_message(chat_id: message.chat.id, text: 'Ты как сюда залез?)')
    end
  end

  def input_substract(message, bot, user)
    message.text.split(' ').map do |pass_number|
      passport = Passport.find(pass_number)
      next unless passport

      passport.update(subscription: passport.subscription - 1)
      if passport.subscription <= 3 && !passport.subscription.zero?
        unless passport.user.nil?
          begin
            bot.api.send_message(chat_id: passport.user.telegram_id,
                                text: "У вас осталось #{passport.subscription} занятий в абонементе")
          rescue
            p 'Что-то пошло не так со списыванием занятий'
          end
        end
      elsif passport.subscription.zero?
        bot.api.send_message(chat_id: 612_352_098,
                             text: "\xE2\x9A\xA0\xEF\xB8\x8F У #{passport.nickname} закончился абонемент \xE2\x9A\xA0\xEF\xB8\x8F")
        begin
          bot.api.send_message(chat_id: passport.user.telegram_id,
                              text: "Ваш абонемент закончился \xF0\x9F\x98\xA2\nБегом за новым \xF0\x9F\x8F\x83")
        rescue
          p 'Что-то пошло не так со списыванием занятий'
        end
      end
    end
    return_buttons(user, bot, message.chat.id, 'Занятия вычтены')
  end
end
