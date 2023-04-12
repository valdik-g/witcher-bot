# frozen_string_literal: true

module ClosePrerecording
  def close_prerecording(message, bot, user)
    if user.admin
      Prerecording.last.update(closed: true)
      available_records = {}
      Prerecording.last.choosed_options.split(',') { |l| available_records[l] = 10 }
      close_message = ''
      Prerecording.last.choosed_options.split(',').each_with_index do |option, i|
        option_prerecord = UserPrerecording.where('days LIKE ?', "%#{i}%")
        option_prerecord.each { |_prer| available_records[option] -= 1 }
        close_message += option + "\n\n" + (option_prerecord.map do |pr|
                                              Passport.find(pr.passport_id).nickname
                                            end).join("\n")
        close_message += "\n\n"
      end
      UserPrerecording.all.each do |pr|
        bot.api.send_message(
          chat_id: User.find_by(passport_id: pr.passport_id).telegram_id, text: 'Предзапись закрыта'
        )
      end
      output_string = ''
      output_string = available_records.map { |l| "#{l[0]}: #{l[1]}\n" }.join
      main_admins_ids.each do |admin|
        bot.api.send_message(chat_id: admin, text: close_message)
        bot.api.send_message(chat_id: admin, text: "Количество свободных мест:\n#{output_string}")
      end
      UserPrerecording.update_all(days: '', message_id: nil)
    else
      bot.api.send_message(chat_id: message.chat.id, text: 'Ты как сюда залез?)')
    end
  end
end
