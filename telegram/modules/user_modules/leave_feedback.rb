# frozen_string_literal: true

# module for leaving feedbacks for users
module LeaveFeedback
  def leave_feedback(message, bot, user)
    if user.passport_id.nil?
      bot.api.send_message(chat_id: message.chat.id,
                           text: 'Похоже к вам еще не привязан паспорт, используйте кнопку Получить свой паспорт')
    else
      bot.api.send_message(chat_id: message.chat.id, text: feedback_prev_text, reply_markup: feedback_markup)
      user.update(step: 'choose_user_visibility')
    end
  end

  def choose_user_visibility(message, bot, user)
    bot.api.send_message(chat_id: message.chat.id, text: 'Введите ваш отзыв', reply_markup: cancel_markup)
    user.update(step: 'enter_feedback')
    message.text
  end

  def enter_feedback(message, bot, user, send_feedbacks_author)
    [822_281_212].each do |admin|
      top = if send_feedbacks_author == 'Открыто'
              "Отзыв от #{user.passport.nickname}:\n\n"
            else
              "Отзыв от кого-то, кто пожелал остаться во мраке ночи:\n\n"
            end
      bot.api.send_message(chat_id: admin, text: top + message.text)
    end
    return_buttons(user, bot, message.chat.id, 'Отзыв отправлен')
  end

  private

  def feedback_prev_text
    'Тут можно оставить свои отзывы и пожелания по нашему клубу, ' \
        'пожелания по будующему функционалу бота, ну и так далее, '\
        'сообщение можно отправить как с подписью так и анонимно'
  end
end
