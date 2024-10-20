# frozen_string_literal: true

# module for adding visitings to subscriptions of users
module AccrueVisitings
  def accrue_visitings(message, bot, user)
    if user.admin
      output_all_passports(bot, message.chat.id)
      bot.api.send_message(chat_id: message.chat.id,
                           text: 'Выберите того, кому необходимо начислить занятия',
                           reply_markup: cancel_markup)
      user.update(step: 'input_subscription_addition')
    else
      bot.api.send_message(chat_id: message.chat.id, text: 'Ты как сюда залез?)')
    end
  end

  def input_subscription_addition(message, bot, user)
    bot.api.send_message(chat_id: message.chat.id, text: 'Сколько?')
    user.update(step: 'add_subscription')
    message.text
  end

  def add_subscription(message, bot, user, passport_id)
    value = message.text
    passport = Passport.find_by(id: passport_id)
    if passport.nil?
      return_buttons(user, bot, message.chat.id)
    else
      passport.update(subscription: passport.subscription + value.to_i)
      return_buttons(user, bot, message.chat.id, 'Занятия начислены')
      subs_user = User.find_by(passport_id: passport.id)
      unless subs_user.nil?
        bot.api.send_message(chat_id: subs_user.telegram_id, text: "Вам начислено #{value} занятия(ий)")
      end
    end
  end
end
