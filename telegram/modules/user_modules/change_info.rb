# frozen_string_literal: true

# module for changing personal info
module ChangeInfo
  def change_info(message, bot, user)
    if user.passport
      bot.api.send_message(chat_id: message.chat.id,
                           text: 'Похоже к вам еще не привязан паспорт, используйте кнопку Получить свой паспорт')
    else
      bot.api.send_message(chat_id: message.chat.id, text: personal_info(user.passport))
      bot.api.send_message(chat_id: message.chat.id, text: change_info_message, reply_markup: cancel_markup)
      user.update(step: 'input_change_info_field')
    end
  end

  def input_change_info_field(message, bot, user)
    info_number = message.text
    case info_number
    when '1' then @update_field = 'bd'
    when '2' then @update_field = 'mail'
    when '3' then @update_field = 'number'
    end
    if %w[1 2 3].include?(info_number)
      bot.api.send_message(chat_id: message.chat.id, text: 'Введите новое значение:')
      user.update(step: 'input_info_value')
      @update_field
    else
      return_buttons(user, bot, message.chat.id, 'Некорректный ввод, повторите команду')
    end
  end

  def input_info_value(message, bot, user, update_field)
    user.passport.update(update_field => message.text)
    return_buttons(user, bot, message.chat.id, 'Значение обновлено')
  end

  private

  def personal_info_message(passport)
    "Личная информация:\n" \
    "1. Дата рождения: #{passport.bd}\n" \
    "2. Почта: #{passport.mail}\n" \
    "3. Телефон: #{passport.number}"
  end

  def change_info_message
    "Что нужно изменить?\n1. Дата рождения\n2. Почта\n3. Телефон\nВводите цифрой"
  end
end
