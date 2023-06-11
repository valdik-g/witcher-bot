# frozen_string_literal: true

module ClosePrerecording
  def close_prerecording(message, bot, user)
    if user.admin
      prerecording = Prerecording.last
      prerecording.update(closed: true)
      av_trainings = prerecording.available_trainings.split(',')
      UserPrerecording.all.each do |pr|
        if Passport.find_by(id: pr.passport_id)
          bot.api.send_message(chat_id: User.find_by(passport_id: pr.passport_id).telegram_id, text: 'Предзапись закрыта')
        end
      end
      output_string = prerecording.choosed_options.split(',').each_with_index.map { |l, i| "#{l}: #{av_trainings[i]}\n" }.join
      User.where(admin: true).collect(&:telegram_id).each do |admin|
        bot.api.send_message(chat_id: admin, text: prerecording.close_message)
        bot.api.send_message(chat_id: admin, text: "Количество свободных мест:\n#{output_string}")
      end
    else
      bot.api.send_message(chat_id: message.chat.id, text: 'Ты как сюда залез?)')
    end
  end
end
