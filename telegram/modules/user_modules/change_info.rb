# frozen_string_literal: true


module ChangeInfo
  def change_info(message, bot, user, cancel_markup)
    if user.passport_id.nil?
      bot.api.send_message(chat_id: message.chat.id,
                           text: 'Похоже к вам еще не привязан паспорт, используйте кнопку Получить свой паспорт')
    else
      passport = user.passport
      bot.api.send_message(chat_id: message.chat.id,
                           text: "Личная информация:\n1. Дата рождения: #{passport.bd}\n2. Почта: #{passport.mail}\n3. Телефон: #{passport.number}")
      bot.api.send_message(chat_id: message.chat.id,
                           text: "Что нужно изменить?\n1. Дата рождения\n2. Почта\n3. Телефон\nВводите цифрой", reply_markup: cancel_markup)
      user.update(step: 'input_change_info_field')
    end
  end

  def input_change_info_field(message, bot, user)
    info_number = message.text
    case info_number
    when '1' then update_field = 'bd'
    when '2' then update_field = 'mail'
    when '3' then update_field = 'number'
    end
    if ['1', '2', '3'].include?(info_number) 
      bot.api.send_message(chat_id: message.chat.id, text: 'Введите новое значение:')
      user.update(step: 'input_info_value')
      update_field
    else
      return_buttons(user, bot, message.chat.id, 'Некорректный ввод, повторите команду')
    end
  end

  def input_info_value(message, bot, user, update_field)
    user.passport.update(update_field => message.text)
    return_buttons(user, bot, message.chat.id, 'Значение обновлено')
  end
end
