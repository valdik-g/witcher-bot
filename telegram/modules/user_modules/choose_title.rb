# frozen_string_literal: true

# mdoule for choosing main title of the player
module ChooseTitle
  def choose_title(message, bot, user, cancel_markup)
    titles = user.passport.titles if user.passport_id
    if titles.nil? || titles.empty?
      bot.api.send_message(chat_id: message.chat.id, text: 'Похоже у вас нет титулов')
    else
      titles_message = titles.map { |title| "#{title.id}: #{title.title_name}\n" }.join
      bot.api.send_message(chat_id: message.chat.id, text: "#{titles_message}\nВыберите основной титул, вводите цифрой",
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
