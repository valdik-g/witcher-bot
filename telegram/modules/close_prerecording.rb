# frozen_string_literal: true

module ClosePrerecording
  def close_prerecording(message, bot, user)
    if user.admin
      prerecording = Prerecording.last
      prerecording.update(closed: true)
      av_trainings = prerecording.available_trainings.split(',')
      UserPrerecording.all.each do |pr|
        bot.api.send_message(chat_id: User.find_by(passport_id: pr.passport_id).telegram_id, text: 'Предзапись закрыта')
      end
      output_string = prerecording.choosed_options.split(',').each_with_index.map { |l, i| "#{l}: #{av_trainings[i]}\n" }.join
      User.where(admin: true).collect(&:telegram_id).each do |admin|
        bot.api.send_message(chat_id: admin, text: close_message(prerecording))
        bot.api.send_message(chat_id: admin, text: "Количество свободных мест:\n#{output_string}")
      end
      Prerecording.last.update(:choosed_options => '', :available_trainings => '', :closed_prerecordings => '')
      UserPrerecording.update_all(days: '', voted: false)
    else
      bot.api.send_message(chat_id: message.chat.id, text: 'Ты как сюда залез?)')
    end
  end

  private 

  def close_message(prerecording)
    close_message = ''
    prerecording.choosed_options.split(',').each_with_index do |option, i|
      option_prerecord = UserPrerecording.where('days LIKE ?', "%#{i}%")
      close_message += option + "\n\n" + (option_prerecord.map do |pr|
                                            Passport.find(pr.passport_id).nickname
                                          end).join("\n")
      close_message += "\n\n"
    end
    close_message
  end
end
