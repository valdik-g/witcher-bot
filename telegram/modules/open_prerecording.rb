# frozen_string_literal: true

# module for open prerecording for users
module OpenPrerecording
  def open_prerecording(message, bot, user, cancel_markup)
    if user.admin
      (Prerecording.last || Prerecording.create).update(closed: false)
      bot.api.send_message(chat_id: message.chat.id, text: 'Введите сообщение', reply_markup: cancel_markup)
      user.update(step: 'input_vote_message')
    else
      bot.api.send_message(chat_id: message.chat.id, text: 'Ты как сюда залез?)')
    end
  end

  def input_vote_message(message, bot, user)
    bot.api.send_poll(chat_id: message.chat.id,
                      question: 'Какие тренировки планируются?', allows_multiple_answers: true,
                      options: %w[Пт Сб1 Сб2 Вс0 Вс1 Вс2],
                      is_anonymous: false)
    user.update(step: 'create_prerecording')
    message.text
  end

  def create_prerecording(message, bot, user, vote_message)
    choosed_options = message.option_ids.map { |l| %w[Пт Сб1 Сб2 Вс0 Вс1 Вс2][l.to_i] }
    Prerecording.last.update(choosed_options: choosed_option.join(','))
    passports = Passport.where('subscription > 0 and subscription < 1000')
    passports.map do |pass|
      next if User.find_by(passport_id: pass.id).nil? || User.find_by(passport_id: pass.id).telegram_id.nil?

      bot.api.send_message(chat_id: User.find_by(passport_id: pass.id).telegram_id, text: vote_message)
      poll_message_id = bot.api.send_poll(chat_id: User.find_by(passport_id: pass.id).telegram_id,
                                          question: 'Куда идем?', allows_multiple_answers: true,
                                          options: choosed_options, is_anonymous: false)
      (UserPrerecording.find_by(passport_id: pass.id) || UserPrerecording.create(passport_id: pass.id))
        .update(message_id: poll_message_id)
    end
    user.update(step: nil)
  end
end
