# frozen_string_literal: true

# module for sending notifications for users
module Notification
  def notification(message, bot, user)
    if user.admin
      bot.api.send_message(chat_id: message.chat.id, text: 'Введите уведомление', reply_markup: cancel_markup)
      user.update(step: 'input_notification')
    else
      bot.api.send_message(chat_id: message.chat.id, text: 'Ты как сюда залез?)')
    end
  end

  def input_notification(message, bot, user)
    Passport.all.each do |p|
      user = User.find_by(passport_id: p.id)
      bot.api.send_message(chat_id: user.telegram_id, text: message.text) unless user.nil?
    end
    return_buttons(user, bot, message.chat.id, 'Сообщение отправлено')
  end
end
