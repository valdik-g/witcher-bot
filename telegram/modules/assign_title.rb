# frozen_string_literal: true

# module for assign titles for witchers
module AssignTitle
  def assign_title(message, bot, user)
    if user.admin
      output_all_passports(bot, message.chat.id)
      bot.api.send_message(chat_id: message.chat.id, text: 'Выберите номер паспорта игрока',
                           reply_markup: cancel_markup)
      user.update(step: 'input_pasport_title')
    else
      bot.api.send_message(chat_id: message.chat.id, text: 'Ты как сюда залез?)')
    end
  end

  def input_pasport_title(message, bot, user)
    titles_message = Title.all.map { |title| "#{title.id} - #{title.title_name}\n" }.join
    bot.api.send_message(chat_id: message.chat.id, text: titles_message)
    bot.api.send_message(chat_id: message.chat.id, text: 'Выберите титул')
    user.update(step: 'choose_title')
    message.text
  end

  def choose_title_to_assign(message, bot, user, passport_id)
    title = Title.find_by(id: message.text)
    passport = Passport.find_by(id: passport_id)
    if title && passport
      passport.titles << title unless passport.titles.include? title
      return_buttons(user, bot, message.chat.id, 'Титул назначен')
    else
      return_buttons(user, bot, message.chat.id)
    end
  end
end
