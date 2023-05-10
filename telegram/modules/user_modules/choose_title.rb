# frozen_string_literal: true

# mdoule for choosing main title of the player
module ChooseTitle
  def choose_title(chat_id, bot, user)
    titles = user.passport.titles if user.passport
    if titles.empty?
      bot.api.send_message(chat_id: chat_id, text: 'Похоже у вас нет титулов')
    else
      bot.api.send_message(chat_id: chat_id, text: "#{titles.map { |t| "#{t.id}: #{t.title_name}\n" }.join}\n" \
                                                   'Выберите основной титул, вводите цифрой',
                           reply_markup: cancel_markup)
      user.update(step: 'input_main_title')
    end
  end

  def input_main_title(message, bot, user)
    id = message.text
    if Title.find_by(id: id).nil?
      message_text = 'Неверный ввод, повторите команду снова'
    else
      user.passport.update(main_title_id: id)
      message_text = 'Основной титул установлен'
    end
    return_buttons(user, bot, message.chat.id, message_text)
  end
end
